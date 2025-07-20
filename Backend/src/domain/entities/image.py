from pydantic import BaseModel

class ImageFile(BaseModel):
    """
    Represents the data and metadata of an uploaded image.
    """
    filename: str
    content_type: str
    content: bytes