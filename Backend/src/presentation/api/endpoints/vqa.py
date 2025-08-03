from fastapi import (
    APIRouter,
    Depends,
    UploadFile,
    File,
    Form,
    HTTPException,
    BackgroundTasks,
)
from starlette import status

from src.application.use_cases.vqa_use_case import VQAUseCase
from src.domain.entities import VQARequest, VQAResult, ImageFile
from src.domain.entities.documents import AnalysisMode
from src.presentation.api.deps import get_vqa_use_case
from src.presentation.api.dependencies import get_user_id, get_models_config

router = APIRouter()


@router.post("/", response_model=VQAResult)
async def vqa_endpoint(
    # --- Dependencies ---
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_user_id),
    use_case: VQAUseCase = Depends(get_vqa_use_case),
    models_config: dict = Depends(get_models_config),

    # --- User Inputs ---
    image: UploadFile = File(...),
    question: str = Form(...),
    model_option: str = Form(...),
    mode: str = Form(...),
):
    """
    Receives a VQA request, provides an immediate answer,
    and logs the full request to the dataset in the background.
    """
    # --- Validation logic added here ---
    vqa_models = models_config.get("vqa", {})
    if not vqa_models.get("selectable") or model_option not in vqa_models.get("models", []):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid model '{model_option}' selected for VQA.",
        )

    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type - only images allowed")

    # --- Analysis Mode Logic ---
    if mode.lower() == "brief":
        analysis_mode = AnalysisMode.BRIEF
    elif mode.lower() == "thorough":
        analysis_mode = AnalysisMode.THOROUGH
    else:
        # Reject invalid modes
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid analysis mode. Must be 'brief' or 'thorough'.",
        )

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )

    # The VQARequest cleanly bundles all the data from the user
    vqa_request = VQARequest(
        user_id=user_id,
        image=image_file,
        question=question,
        model_option=model_option,
        mode=analysis_mode,
    )

    # Await the use case and pass the background_tasks object to it
    return await use_case.execute(vqa_request, background_tasks)