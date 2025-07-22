# Backend/src/presentation/api/endpoints/vqa.py
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from src.application.use_cases.vqa_use_case import VQAUseCase
from src.domain.entities import ImageFile, VQARequest, VQAResult
from src.presentation.api.deps import get_vqa_use_case

# Import the configuration from your new control panel
from .config import ACTIVE_MODELS_CONFIG

router = APIRouter()


@router.post("/", response_model=VQAResult)
async def vqa_endpoint(
        # The 'option' parameter is GONE. The frontend no longer sends it.
        question: str = Form(...),
        image: UploadFile = File(...),
        use_case: VQAUseCase = Depends(get_vqa_use_case)
):
    """
    Receives an image and a question, determines the correct model internally,
    and returns a VQA result.
    """
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )

    # The backend now dictates the model to use.
    # It reads directly from the imported configuration object.
    backend_selected_model = ACTIVE_MODELS_CONFIG.vqa_model

    # The VQARequest object is now populated with the backend's choice.
    vqa_request = VQARequest(
        question=question,
        model_option=backend_selected_model,  # Use the model from our config
        image=image_file
    )

    # The use case proceeds as normal, but with the backend-defined model.
    return use_case.execute(vqa_request)