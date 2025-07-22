# Backend/src/presentation/api/endpoints/ocr.py
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from src.application.use_cases.ocr_use_case import OCRUseCase
from src.domain.entities import ImageFile, OCRRequest, OCRResult
from src.presentation.api.deps import get_ocr_use_case

# Import the configuration from your central control panel
from .config import ACTIVE_MODELS_CONFIG

router = APIRouter()


@router.post("/", response_model=OCRResult)
async def ocr_endpoint(
        # The 'option' parameter is REMOVED from the function signature.
        image: UploadFile = File(...),
        use_case: OCRUseCase = Depends(get_ocr_use_case)
):
    """
    Receives an image, determines the correct model internally,
    and returns the extracted text.
    """
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )

    # The backend now dictates the model to use for OCR.
    backend_selected_model = ACTIVE_MODELS_CONFIG.ocr_model

    # The OCRRequest is now populated with the backend's choice.
    ocr_request = OCRRequest(
        model_option=backend_selected_model,  # Use the model from our config
        image=image_file
    )

    return use_case.execute(ocr_request)