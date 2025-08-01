# Backend/src/presentation/api/endpoints/config.py
from pydantic import BaseModel
from fastapi import APIRouter

class FeatureConfig(BaseModel):
    """
    Defines the active model for each feature.
    """
    vqa_model: str
    ocr_model: str
    video_scene_extractor: str
    video_scene_aggregator: str
    video_scene_qa: str


router = APIRouter()

# This is your new control panel.
# Change the model ID here, and the app will use it automatically.
# This can be loaded from a .env file or a database for more power.
ACTIVE_MODELS_CONFIG = FeatureConfig(
    vqa_model="gemini-2.5-flash",
    ocr_model="gemini-2.5-pro",
    video_scene_extractor="gemini-2.5-flash",
    video_scene_aggregator="gemini-2.5-pro",
    video_scene_qa="gemini-2.5-pro",
)
