from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Form
from starlette import status

from src.application.use_cases.ocr_use_case import OCRUseCase
from src.domain.entities import ImageFile, OCRRequest, OCRResult
from src.presentation.api.deps import get_ocr_use_case
from src.presentation.api.dependencies import get_models_config

router = APIRouter()

@router.post("/", response_model=OCRResult)
async def ocr_endpoint(
        # --- Dependencies ---
        use_case: OCRUseCase = Depends(get_ocr_use_case),
        models_config: dict = Depends(get_models_config),

        # --- User Inputs ---
        image: UploadFile = File(...),
        model_option: str = Form(...),
):
    """
    Receives an image, determines the correct model internally,
    and returns the extracted text.
    """
    ocr_models = models_config.get("ocr", {})
    if not ocr_models.get("selectable") or model_option not in ocr_models.get("models", []):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid model '{model_option}' selected for OCR.",
        )

    if not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )


    ocr_request = OCRRequest(
        model_option=model_option,
        image=image_file
    )

    # Await the asynchronous use case call
    return await use_case.execute(ocr_request)