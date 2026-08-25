import os
import json
from PIL import Image, ImageDraw

BENCHMARK_DIR = os.path.dirname(os.path.abspath(__file__))
IMAGES_DIR = os.path.join(BENCHMARK_DIR, "images")
SWEEP_JSON_PATH = os.path.join(BENCHMARK_DIR, "reports", "threshold_sweep.json")
OUTPUT_FINAL_DIR = os.path.join(BENCHMARK_DIR, "outputs", "final_grounding_dino")
os.makedirs(OUTPUT_FINAL_DIR, exist_ok=True)

SELECTED_THRESHOLD = 0.35

with open(SWEEP_JSON_PATH, "r") as f:
    sweep_data = json.load(f)

predictions = sweep_data["predictions"]

colors = ["#00FFCC", "#FF3366", "#33CCFF", "#FFCC00", "#9966FF", "#00FF66"]

for img_name, preds in predictions.items():
    img_path = os.path.join(IMAGES_DIR, img_name)
    if not os.path.exists(img_path):
        continue
        
    img = Image.open(img_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    w, h = img.size
    
    # Deduplicate predictions in single image by label & score
    filtered_preds = [p for p in preds if p["score"] >= SELECTED_THRESHOLD]
    
    for idx, det in enumerate(filtered_preds):
        box = det["box"] # [x1, y1, x2, y2]
        label = det["label"]
        score = det["score"]
        
        color = colors[idx % len(colors)]
        draw.rectangle(box, outline=color, width=3)
        text = f"{label}: {score:.2f}"
        
        text_bbox = draw.textbbox((box[0], max(0, box[1] - 18)), text)
        draw.rectangle(text_bbox, fill=color)
        draw.text((box[0], max(0, box[1] - 18)), text, fill="black")
        
    out_path = os.path.join(OUTPUT_FINAL_DIR, img_name)
    img.save(out_path)
    print(f"🖼️ Saved final annotated output: {out_path} ({len(filtered_preds)} items)")

print("\n✅ Final annotated benchmark images generated successfully!")
