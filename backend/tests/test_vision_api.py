"""Unit tests for POST /api/v1/vision/detect endpoint."""

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_vision_detect_no_images():
    response = client.post("/api/v1/vision/detect")
    assert response.status_code == 422 or response.status_code == 400


@patch("app.services.vision_detector.VisionDetectorService.detect_objects_in_image")
def test_vision_detect_success(mock_detect):
    mock_detect.return_value = [
        {
            "id": "det_mock_sofa",
            "name": "Sofa",
            "label": "sofa",
            "category": "furniture",
            "roomName": "Living Room",
            "confidence": 0.92,
            "sourceImageId": "img_0",
            "normalizedBoundingBox": [0.10, 0.20, 0.50, 0.40],
            "aiMetadata": {"model": "IDEA-Research/grounding-dino-tiny", "threshold": 0.35}
        }
    ]

    # Create dummy image bytes
    fake_image_bytes = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.' \",#\x1c\x1c(7),01444\x1f'9=82<.342\xff\xc0\x00\x0b\x08\x00\x0a\x00\x0a\x01\x01\x11\x00\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xbf\x00\xff\xd9"

    files = [("images", ("test_room.jpg", fake_image_bytes, "image/jpeg"))]
    data = {"room_name": "Living Room", "image_ids": ["img_0"]}

    response = client.post("/api/v1/vision/detect", data=data, files=files)
    assert response.status_code == 200
    res_data = response.json()

    assert res_data["status"] == "success"
    assert res_data["roomName"] == "Living Room"
    assert res_data["totalDetections"] == 1
    assert len(res_data["detections"]) == 1

    det = res_data["detections"][0]
    assert det["name"] == "Sofa"
    assert det["label"] == "sofa"
    assert det["confidence"] == 0.92
    assert det["normalizedBoundingBox"] == [0.10, 0.20, 0.50, 0.40]
