from fastapi import APIRouter
from .endpoints import vqa, ocr, live_session, config, user

api_router = APIRouter()

api_router.include_router(user.router, prefix="/users", tags=["Users"])
api_router.include_router(vqa.router, prefix="/vqa", tags=["VQA"])
api_router.include_router(ocr.router, prefix="/ocr", tags=["OCR"])
api_router.include_router(live_session.router, prefix="/session", tags=["Live Session"])
api_router.include_router(config.router, prefix="/config", tags=["Configuration"])