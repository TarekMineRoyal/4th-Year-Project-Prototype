# src/domain/entities/user.py

from pydantic import BaseModel, Field
import uuid

class UserInitResponse(BaseModel):
    """
    The response model for the user initialization endpoint.
    """
    user_id: uuid.UUID = Field(..., description="The unique ID generated for the user.")