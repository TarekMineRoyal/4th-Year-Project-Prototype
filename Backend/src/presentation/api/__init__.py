from fastapi import APIRouter
from .endpoints import vqa, ocr, video_analysis, config

api_router = APIRouter()

api_router.include_router(vqa.router, prefix="/vqa", tags=["VQA"])
api_router.include_router(ocr.router, prefix="/ocr", tags=["OCR"])
api_router.include_router(video_analysis.router, prefix="/video", tags=["Video Analysis"])
api_router.include_router(config.router, prefix="/config", tags=["Configuration"])