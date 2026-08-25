"""Unit tests for VisionConfig settings, threshold filtering, and synonym normalization."""

from app.core.config import settings

def test_vision_config_defaults():
    assert settings.VISION_DETECTION_THRESHOLD == 0.35
    assert settings.VISION_MODEL_ID == "IDEA-Research/grounding-dino-tiny"

def test_canonical_vocabulary_and_synonyms():
    from vision_benchmark.threshold_sweep import normalize_label
    
    assert normalize_label("couch") == "sofa"
    assert normalize_label("tv") == "television"
    assert normalize_label("fridge") == "refrigerator"
    assert normalize_label("coffee table") == "coffee_table"
    assert normalize_label("random_irrelevant_noise") is None
