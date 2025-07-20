from pydantic import BaseModel, Field
from typing import Optional
from .image import ImageFile

class VQARequest(BaseModel):
    """
    Input model for the VQA use case.
    """
    question: str
    model_option: str
    image: ImageFile

class VQAResult(BaseModel):
    """
    Output model for a successful VQA analysis.
    """
    answer: str
    processing_time: float = Field(..., ge=0)
    analyzed_path: Optional[str] = None