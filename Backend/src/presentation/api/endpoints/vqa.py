from fastapi import (
    APIRouter,
    Depends,
    UploadFile,
    File,
    Form,
    HTTPException,
    BackgroundTasks,
)
from src.application.use_cases.vqa_use_case import VQAUseCase
from src.domain.entities import VQARequest, VQAResult, ImageFile
from src.domain.entities.documents import AnalysisMode
from src.presentation.api.deps import get_vqa_use_case
from src.presentation.api.dependencies import get_user_id
from src.presentation.api.endpoints.config import ACTIVE_MODELS_CONFIG

router = APIRouter()


@router.post("/", response_model=VQAResult)
async def vqa_endpoint(
    # --- Dependencies ---
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_user_id),
    use_case: VQAUseCase = Depends(get_vqa_use_case),

    # --- User Inputs ---
    image: UploadFile = File(...),
    question: str = Form(...),
):
    """
    Receives a VQA request, provides an immediate answer,
    and logs the full request to the dataset in the background.
    """
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )

    # The VQARequest cleanly bundles all the data from the user
    vqa_request = VQARequest(
        user_id=user_id,
        image=image_file,  # Pass the UploadFile directly, the use case will read it
        question=question,
        model_option=ACTIVE_MODELS_CONFIG.vqa_model,
        mode=AnalysisMode.BRIEF,
    )

    # Await the use case and pass the background_tasks object to it
    return await use_case.execute(vqa_request, background_tasks)