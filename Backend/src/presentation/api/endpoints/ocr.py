from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from src.application.use_cases.ocr_use_case import OCRUseCase
from src.domain.entities import ImageFile, OCRRequest, OCRResult
from src.presentation.api.deps import get_ocr_use_case

router = APIRouter()

@router.post("/", response_model=OCRResult)
async def ocr_endpoint(
    image: UploadFile = File(...),
    use_case: OCRUseCase = Depends(get_ocr_use_case)
):
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )
    ocr_request = OCRRequest(image=image_file)
    return use_case.execute(ocr_request)