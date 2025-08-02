from fastapi import Header, HTTPException
from typing import Optional

async def get_user_id(x_user_id: Optional[str] = Header(None, alias="X-User-ID")) -> str:
    """
    Retrieves and validates the X-User-ID from the request headers.
    """
    if not x_user_id:
        raise HTTPException(status_code=400, detail="X-User-ID header is missing.")
    return x_user_id