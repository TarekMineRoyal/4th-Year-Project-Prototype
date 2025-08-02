from pydantic import BaseModel, Field
from typing import Optional

from .documents import AnalysisMode
from .image import ImageFile

class VQARequest(BaseModel):
    """
    Input model for the VQA use case.
    """
    user_id: str
    question: str
    model_option: str
    mode: AnalysisMode
    image: ImageFile

class VQAResult(BaseModel):
    """
    Output model for a successful VQA analysis.
    """
    answer: str
    processing_time: float = Field(..., ge=0)
    analyzed_path: Optional[str] = None