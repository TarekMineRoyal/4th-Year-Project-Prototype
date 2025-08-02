# src/domain/documents.py

from beanie import Document
from pydantic import Field
from typing import Optional
import uuid
import enum  # Import enum


# Define the allowed modes using an Enum
class AnalysisMode(str, enum.Enum):
    BRIEF = "brief"
    THOROUGH = "thorough"


class RequestLog(Document):
    """
    A unified document to log every VQA request for dataset creation.
    """
    id: uuid.UUID = Field(default_factory=uuid.uuid4)
    user_id: str = Field(..., description="The anonymous unique ID of the user.")
    model_name: str = Field(..., description="The name of the model used for the analysis.")
    mode: AnalysisMode = Field(..., description="The analysis mode selected by the user.")
    file_path: str = Field(..., description="The path to the saved media file.")
    question: Optional[str] = Field(None, description="The question asked by the user (for VQA).")
    answer: str = Field(..., description="The generated answer or extracted text.")
    list_of_objects: list[str] = Field(..., description="A list of objects detected in the media.")

    class Settings:
        name = "request_logs"