"""Production Vision Detector Service using Grounding DINO Tiny."""

import os
import time
import torch
import logging
from typing import List, Dict, Any, Optional
from PIL import Image
from transformers import AutoProcessor, AutoModelForZeroShotObjectDetection

from app.core.config import settings

logger = logging.getLogger(__name__)

# Canonical KleenAI vocabulary and category mapping
CANONICAL_VOCABULARY = [
    "sofa", "chair", "bed", "coffee_table", "dining_table", "desk", 
    "tv_stand", "television", "rug", "carpet", "hardwood_floor", 
    "tile_floor", "window", "windowsill", "mirror", "shelf", "cabinet", 
    "countertop", "sink", "toilet", "bathtub", "shower", "refrigerator", 
    "stovetop", "oven", "house_plant", "lamp", "nightstand", "dresser"
]

CATEGORY_MAPPING = {
    "sofa": "furniture",
    "chair": "furniture",
    "bed": "furniture",
    "coffee_table": "furniture",
    "dining_table": "furniture",
    "desk": "furniture",
    "tv_stand": "furniture",
    "shelf": "furniture",
    "cabinet": "furniture",
    "nightstand": "furniture",
    "dresser": "furniture",
    "television": "electronics",
    "lamp": "electronics",
    "refrigerator": "electronics",
    "stovetop": "electronics",
    "oven": "electronics",
    "hardwood_floor": "surfaces",
    "tile_floor": "surfaces",
    "carpet": "surfaces",
    "rug": "surfaces",
    "countertop": "surfaces",
    "windowsill": "surfaces",
    "window": "surfaces",
    "mirror": "surfaces",
    "sink": "surfaces",
    "toilet": "surfaces",
    "bathtub": "surfaces",
    "shower": "surfaces",
    "house_plant": "other",
}

SYNONYM_MAP = {
    "couch": "sofa",
    "armchair": "chair",
    "table": "dining_table",
    "desk lamp": "lamp",
    "floor lamp": "lamp",
    "tv": "television",
    "tv screen": "television",
    "plant": "house_plant",
    "potted plant": "house_plant",
    "area rug": "rug",
    "mat": "rug",
    "cupboard": "cabinet",
    "counter": "countertop",
    "washbasin": "sink",
    "kitchen sink": "sink",
    "fridge": "refrigerator",
    "cooktop": "stovetop",
    "stove": "stovetop",
    "window sill": "windowsill",
    "bookcase": "shelf",
    "bookshelf": "shelf",
}


def normalize_label(raw_label: str) -> Optional[str]:
    """Normalize raw model label output to canonical KleenAI concept."""
    clean = raw_label.lower().strip().replace("_", " ")
    if clean in SYNONYM_MAP:
        clean = SYNONYM_MAP[clean]
    canon_match = clean.replace(" ", "_")
    if canon_match in CANONICAL_VOCABULARY:
        return canon_match
    return None


class VisionDetectorService:
    """Singleton service holding Grounding DINO model in memory for fast inference."""

    _instance: Optional["VisionDetectorService"] = None

    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else ("mps" if torch.backends.mps.is_available() else "cpu")
        self.model_id = settings.VISION_MODEL_ID
        self.threshold = settings.VISION_DETECTION_THRESHOLD
        self._processor = None
        self._model = None

    @classmethod
    def get_instance(cls) -> "VisionDetectorService":
        if cls._instance is None:
            cls._instance = VisionDetectorService()
        return cls._instance

    def initialize_model(self):
        """Lazy load Grounding DINO processor and weights ONCE into memory."""
        if self._model is not None and self._processor is not None:
            return

        logger.info(f"⚡ Initializing VisionDetectorService with {self.model_id} on {self.device.upper()}...")
        t0 = time.time()
        self._processor = AutoProcessor.from_pretrained(self.model_id)
        self._model = AutoModelForZeroShotObjectDetection.from_pretrained(self.model_id).to(self.device)
        self._model.eval()
        logger.info(f"✅ Vision Model Loaded in {time.time() - t0:.2f}s")

    def detect_objects_in_image(
        self, 
        image_path: str, 
        source_image_id: str,
        room_name: str = "Living Room"
    ) -> List[Dict[str, Any]]:
        """Run Grounding DINO detection on a single image and return normalized DTOs."""
        self.initialize_model()

        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image path not found: {image_path}")

        image = Image.open(image_path).convert("RGB")
        w_img, h_img = image.size

        prompt_text = ". ".join(CANONICAL_VOCABULARY).replace("_", " ") + "."
        inputs = self._processor(images=image, text=prompt_text, return_tensors="pt").to(self.device)

        t_start = time.time()
        with torch.no_grad():
            outputs = self._model(**inputs)

        target_sizes = torch.tensor([[h_img, w_img]]).to(self.device)
        results_post = self._processor.post_process_grounded_object_detection(
            outputs,
            inputs.input_ids,
            threshold=self.threshold,
            text_threshold=self.threshold,
            target_sizes=target_sizes
        )[0]

        latency = time.time() - t_start
        logger.info(f" 📸 Inference completed for {source_image_id} in {latency * 1000:.0f}ms")

        detections = []
        for idx, (score, label, box) in enumerate(zip(results_post["scores"], results_post["labels"], results_post["boxes"])):
            score_val = float(score)
            norm_label = normalize_label(label)
            if norm_label is None:
                continue

            # Absolute box coordinates [x1, y1, x2, y2]
            box_coords = [float(b) for b in box]
            x1, y1, x2, y2 = box_coords

            # Convert to normalized [left, top, width, height] in 0..1 range
            left = max(0.0, min(1.0, x1 / w_img))
            top = max(0.0, min(1.0, y1 / h_img))
            width = max(0.0, min(1.0 - left, (x2 - x1) / w_img))
            height = max(0.0, min(1.0 - top, (y2 - y1) / h_img))

            category = CATEGORY_MAPPING.get(norm_label, "other")
            display_name = norm_label.replace("_", " ").title()

            detections.append({
                "id": f"det_{int(time.time() * 1000)}_{source_image_id}_{idx}",
                "name": display_name,
                "label": norm_label,
                "category": category,
                "roomName": room_name,
                "confidence": round(score_val, 4),
                "sourceImageId": source_image_id,
                "normalizedBoundingBox": [
                    round(left, 4),
                    round(top, 4),
                    round(width, 4),
                    round(height, 4)
                ],
                "aiMetadata": {
                    "model": self.model_id,
                    "threshold": self.threshold,
                    "inferenceTimeMs": round(latency * 1000, 2)
                }
            })

        return detections
