"""FastAPI Endpoint for Vision Object Detection."""

import os
import shutil
import tempfile
import logging
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, status, Depends

from app.core.config import settings
from app.services.vision_detector import VisionDetectorService
from app.api.deps import get_current_user_optional

logger = logging.getLogger(__name__)

router = APIRouter()

ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB max per image
MAX_IMAGES_PER_REQUEST = 5


@router.post("/detect")
async def detect_objects(
    room_id: Optional[str] = Form(None),
    room_name: Optional[str] = Form("Living Room"),
    image_ids: Optional[List[str]] = Form(None),
    images: List[UploadFile] = File(...),
    current_user: Optional[dict] = Depends(get_current_user_optional)
):
    """
    Accepts 1-5 room images and returns real Grounding DINO detected objects
    with normalized 0..1 bounding boxes and canonical labels.
    """
    if not images or len(images) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No images uploaded. At least 1 image is required."
        )

    if len(images) > MAX_IMAGES_PER_REQUEST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum {MAX_IMAGES_PER_REQUEST} images allowed per request."
        )

    detector = VisionDetectorService.get_instance()
    all_detections = []
    
    # Process files inside a guaranteed temporary directory for automatic cleanup
    with tempfile.TemporaryDirectory() as temp_dir:
        for idx, img_file in enumerate(images):
            filename = img_file.filename or f"image_{idx}.jpg"
            ext = os.path.splitext(filename)[1].lower()
            if ext not in ALLOWED_IMAGE_EXTENSIONS:
                ext = ".jpg"

            temp_path = os.path.join(temp_dir, f"temp_{idx}{ext}")
            
            # Read and validate size
            contents = await img_file.read()
            if len(contents) > MAX_FILE_SIZE_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Image {filename} exceeds maximum size limit of 15MB."
                )

            if len(contents) == 0:
                continue

            with open(temp_path, "wb") as f:
                f.write(contents)

            # Determine source image ID
            source_img_id = f"img_{idx}"
            if image_ids and idx < len(image_ids):
                source_img_id = image_ids[idx]

            try:
                img_detections = detector.detect_objects_in_image(
                    image_path=temp_path,
                    source_image_id=source_img_id,
                    room_name=room_name or "Living Room"
                )
                all_detections.extend(img_detections)
            except Exception as e:
                logger.error(f"❌ Detection failed for image {filename}: {e}", exc_info=True)

    return {
        "status": "success",
        "roomId": room_id or "room_default",
        "roomName": room_name or "Living Room",
        "model": settings.VISION_MODEL_ID,
        "threshold": settings.VISION_DETECTION_THRESHOLD,
        "totalDetections": len(all_detections),
        "detections": all_detections
    }
