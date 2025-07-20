from pydantic import BaseModel, Field
from typing import Optional
from .image import ImageFile

class VideoAnalysisRequest(BaseModel):
    """
    Input model for the video analysis use case.
    """
    previous_scene_description: str
    image: ImageFile

class VideoAnalysisResult(BaseModel):
    """
    Output model of a video analysis frame.
    """
    description_of_change: str
    has_changed: bool
    processing_time: float = Field(..., ge=0)
    analyzed_path: Optional[str] = None