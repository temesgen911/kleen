import os
import json
import time
import torch
from PIL import Image
from transformers import AutoProcessor, AutoModelForZeroShotObjectDetection

BENCHMARK_DIR = os.path.dirname(os.path.abspath(__file__))
IMAGES_DIR = os.path.join(BENCHMARK_DIR, "images")
GROUND_TRUTH_PATH = os.path.join(BENCHMARK_DIR, "ground_truth", "ground_truth.json")
OUTPUT_FINAL_DIR = os.path.join(BENCHMARK_DIR, "outputs", "final_grounding_dino")
os.makedirs(OUTPUT_FINAL_DIR, exist_ok=True)

with open(GROUND_TRUTH_PATH, "r") as f:
    gt_data = json.load(f)

CANONICAL_VOCAB = set(gt_data["canonical_vocabulary"])
SYNONYM_MAP = gt_data["synonym_map"]
IMAGES_GT = gt_data["images"]

device = "cuda" if torch.cuda.is_available() else ("mps" if torch.backends.mps.is_available() else "cpu")

def normalize_label(raw_label):
    clean = raw_label.lower().strip().replace("_", " ")
    if clean in SYNONYM_MAP:
        clean = SYNONYM_MAP[clean]
    canon_match = clean.replace(" ", "_")
    if canon_match in CANONICAL_VOCAB:
        return canon_match
    return None # Filter out non-canonical noisy detections

def run_sweep():
    print(f"⚡ Loading Grounding DINO Tiny on {device.upper()} for Threshold Sweep...")
    model_id = "IDEA-Research/grounding-dino-tiny"
    processor = AutoProcessor.from_pretrained(model_id)
    model = AutoModelForZeroShotObjectDetection.from_pretrained(model_id).to(device)
    model.eval()

    prompt_text = ". ".join(list(CANONICAL_VOCAB)).replace("_", " ") + "."
    
    # Store raw predictions per image: list of (confidence, normalized_label, [x1,y1,x2,y2])
    all_raw_predictions = {}
    
    for img_name, meta in IMAGES_GT.items():
        img_path = os.path.join(IMAGES_DIR, img_name)
        if not os.path.exists(img_path):
            continue
        image = Image.open(img_path).convert("RGB")
        inputs = processor(images=image, text=prompt_text, return_tensors="pt").to(device)
        
        with torch.no_grad():
            outputs = model(**inputs)
            
        target_sizes = torch.tensor([image.size[::-1]]).to(device)
        # Use low threshold 0.15 to capture all candidates for sweep
        results_post = processor.post_process_grounded_object_detection(
            outputs, 
            inputs.input_ids,
            threshold=0.15,
            text_threshold=0.15,
            target_sizes=target_sizes
        )[0]
        
        preds = []
        for score, label, box in zip(results_post["scores"], results_post["labels"], results_post["boxes"]):
            score_val = float(score)
            box_list = [float(x) for x in box] # [x1, y1, x2, y2]
            norm_label = normalize_label(label)
            if norm_label is not None:
                preds.append({"score": score_val, "label": norm_label, "box": box_list, "w": image.width, "h": image.height})
                
        all_raw_predictions[img_name] = preds

    thresholds = [0.25, 0.30, 0.35, 0.40, 0.45, 0.50]
    sweep_results = []

    print("\n==========================================")
    print("📊 GROUNDING DINO THRESHOLD SWEEP RESULTS")
    print("==========================================")

    for thresh in thresholds:
        tp_total = 0
        fp_total = 0
        fn_total = 0
        
        for img_name, meta in IMAGES_GT.items():
            expected = set(meta["expected_objects"])
            preds = all_raw_predictions.get(img_name, [])
            
            # Filter predictions by current threshold
            filtered_labels = set([p["label"] for p in preds if p["score"] >= thresh])
            
            tp = len(filtered_labels.intersection(expected))
            fp = len(filtered_labels - expected)
            fn = len(expected - filtered_labels)
            
            tp_total += tp
            fp_total += fp
            fn_total += fn

        precision = tp_total / (tp_total + fp_total) if (tp_total + fp_total) > 0 else 0.0
        recall = tp_total / (tp_total + fn_total) if (tp_total + fn_total) > 0 else 0.0
        f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0

        sweep_results.append({
            "threshold": thresh,
            "precision": round(precision, 3),
            "recall": round(recall, 3),
            "f1": round(f1, 3),
            "true_positives": tp_total,
            "false_positives": fp_total,
            "false_negatives": fn_total
        })

        print(f"Thresh: {thresh:.2f} | Precision: {precision:.3f} | Recall: {recall:.3f} | F1: {f1:.3f} | TP: {tp_total} | FP: {fp_total} | FN: {fn_total}")

    # Output JSON summary
    sweep_summary_path = os.path.join(BENCHMARK_DIR, "reports", "threshold_sweep.json")
    with open(sweep_summary_path, "w") as f:
        json.dump({"sweep": sweep_results, "predictions": all_raw_predictions}, f, indent=2)
        
    print(f"\n✅ Sweep data written to {sweep_summary_path}")

if __name__ == "__main__":
    run_sweep()
