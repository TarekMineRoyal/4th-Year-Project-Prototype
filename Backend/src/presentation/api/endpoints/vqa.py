from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from src.application.use_cases.vqa_use_case import VQAUseCase
from src.domain.entities import ImageFile, VQARequest, VQAResult
from src.presentation.api.deps import get_vqa_use_case

router = APIRouter()

@router.post("/", response_model=VQAResult)
async def vqa_endpoint(
    option: str = Form(...),
    question: str = Form(...),
    image: UploadFile = File(...),
    use_case: VQAUseCase = Depends(get_vqa_use_case)
):
    if not image.content_type.startswith('image/'):
        raise HTTPException(400, "Invalid file type - only images allowed")

    image_content = await image.read()
    image_file = ImageFile(
        filename=image.filename,
        content_type=image.content_type,
        content=image_content
    )
    vqa_request = VQARequest(
        question=question,
        model_option=option,
        image=image_file
    )
    return use_case.execute(vqa_request)