from pydantic import BaseModel

class ImageFile(BaseModel):
    """
    Represents the data and metadata of an uploaded image.
    """
    filename: str # The original name of the file as it was on the user's device
    content_type: str # The MIME type of the file (e.g., "image/jpeg")
    content: bytes # The actual raw data of the image