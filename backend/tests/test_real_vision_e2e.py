"""End-to-end integration test with real Grounding DINO model inference on real benchmark image."""

import os
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

BENCHMARK_IMAGE = os.path.join(
    os.path.dirname(__file__), 
    "..", 
    "vision_benchmark", 
    "images", 
    "room_01_living.jpg"
)


@pytest.mark.skipif(not os.path.exists(BENCHMARK_IMAGE), reason="Benchmark image missing")
def test_real_vision_e2e_inference():
    with open(BENCHMARK_IMAGE, "rb") as f:
        image_bytes = f.read()

    files = [("images", ("room_01_living.jpg", image_bytes, "image/jpeg"))]
    data = {"room_name": "Living Room", "image_ids": ["img_living_01"]}

    response = client.post("/api/v1/vision/detect", data=data, files=files)
    assert response.status_code == 200

    res = response.json()
    assert res["status"] == "success"
    assert res["roomName"] == "Living Room"
    assert res["model"] == "IDEA-Research/grounding-dino-tiny"
    assert res["threshold"] == 0.35
    assert res["totalDetections"] >= 3

    detected_names = [d["name"] for d in res["detections"]]
    print(f"\n📸 Real DINO Detections: {detected_names}")

    for det in res["detections"]:
        box = det["normalizedBoundingBox"]
        assert len(box) == 4
        # Validate 0 <= left, top, width, height <= 1
        assert 0.0 <= box[0] <= 1.0
        assert 0.0 <= box[1] <= 1.0
        assert 0.0 <= box[2] <= 1.0
        assert 0.0 <= box[3] <= 1.0
