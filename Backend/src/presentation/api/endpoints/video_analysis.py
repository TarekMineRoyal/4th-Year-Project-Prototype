# Backend/src/presentation/api/endpoints/video_analysis.py
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from src.application.use_cases.video_analysis_use_case import VideoAnalysisUseCase
from src.domain.entities import ImageFile, VideoAnalysisRequest, VideoAnalysisResult
from src.presentation.api.deps import get_video_analysis_use_case

# Import the configuration from your central control panel
from .config import ACTIVE_MODELS_CONFIG

router = APIRouter()


@router.post("/", response_model=VideoAnalysisResult)
async def video_analysis_endpoint(
        previous_scene_description: str = Form(...),
        image: UploadFile = File(...),
        use_case: VideoAnalysisUseCase = Depends(get_video_analysis_use_case)
):
    """
    Receives an image and previous context, determines the correct model internally,
    and returns the new scene description.
    """
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )

    # The backend now dictates the model to use for Video Analysis.
    backend_selected_model = ACTIVE_MODELS_CONFIG.video_analysis_model

    # The request is now populated with the backend's choice.
    video_request = VideoAnalysisRequest(
        model_option=backend_selected_model,  # Use the model from the config
        previous_scene_description=previous_scene_description,
        image=image_file
    )

    return use_case.execute(video_request)