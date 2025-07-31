from pydantic import BaseModel, validator

class VideoFile(BaseModel):
    """
    Represents the data and metadata of an uploaded video file.
    """
    filename: str
    content_type: str
    content: bytes
