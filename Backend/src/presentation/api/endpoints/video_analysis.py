from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from src.application.use_cases.video_analysis_use_case import VideoAnalysisUseCase
from src.domain.entities import ImageFile, VideoAnalysisRequest, VideoAnalysisResult
from src.presentation.api.deps import get_video_analysis_use_case

router = APIRouter()

@router.post("/", response_model=VideoAnalysisResult)
async def video_analysis_endpoint(
    previous_scene_description: str = Form(...),
    image: UploadFile = File(...),
    use_case: VideoAnalysisUseCase = Depends(get_video_analysis_use_case)
):
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )
    video_request = VideoAnalysisRequest(
        previous_scene_description=previous_scene_description,
        image=image_file
    )
    return use_case.execute(video_request)