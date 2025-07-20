from pydantic import BaseModel, Field
from typing import Optional
from .image import ImageFile

class OCRRequest(BaseModel):
    """
    Input model for the OCR use case.
    """
    image: ImageFile

class OCRResult(BaseModel):
    """
    Output model for a successful OCR analysis.
    """
    text: str
    processing_time: float = Field(..., ge=0)
    analyzed_path: Optional[str] = None