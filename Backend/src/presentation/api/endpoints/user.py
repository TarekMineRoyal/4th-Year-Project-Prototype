# src/presentation/api/endpoints/user.py

import uuid
from fastapi import APIRouter, status
from src.domain.entities.user import UserInitResponse
import structlog

router = APIRouter()

logger = structlog.get_logger(__name__)

@router.post(
    "/init",
    response_model=UserInitResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new unique User ID"
)
def create_user_id():
    """
    Generates a new, unique user ID for a first-time app launch.
    The mobile client should store this ID securely and use it in the
    'X-User-ID' header for all subsequent API calls.
    """
    new_id = uuid.uuid4()
    logger.info("New user initialized.", new_id=new_id)
    return UserInitResponse(user_id=new_id)