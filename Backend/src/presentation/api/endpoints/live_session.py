import structlog
from fastapi import (
    APIRouter,
    Depends,
    UploadFile,
    File,
    Form,
    HTTPException,
    BackgroundTasks,
    status,
)

from .config import ACTIVE_MODELS_CONFIG
from src.application.use_cases.live_session_use_case import LiveSessionUseCase
from src.domain.entities import (
    ImageFile,
    VideoFile,
    SessionCreationResult,
    SessionQueryResult,
    SessionQueryRequest,
)
from src.presentation.api.deps import get_live_session_use_case
from src.domain.entities.live_session import SessionAnalysVideoRequest

# Get a logger instance for this module
logger = structlog.get_logger(__name__)

router = APIRouter()


@router.post("/start", response_model=SessionCreationResult, status_code=status.HTTP_201_CREATED)
def start_session_endpoint(
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
):
    """
    Starts a new live session and returns a unique session ID for the client to use.
    """
    try:
        session_id = use_case.create_session()
        logger.info("API: New session started successfully.", session_id=session_id)
        return SessionCreationResult(session_id=session_id)
    except Exception as e:
        logger.exception("API: Failed to start a new session.")
        raise HTTPException(status_code=500, detail=f"Failed to create session: {e}")


@router.post("/process-clip", status_code=status.HTTP_202_ACCEPTED)
async def process_clip_endpoint(
        background_tasks: BackgroundTasks,
        session_id: str = Form(...),
        video_clip: UploadFile = File(...),
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
):
    """
    Accepts a video clip for asynchronous processing.
    It saves the clip, adds the analysis to a background task queue,
    and returns immediately.
    """
    logger.info("API: Received request to process video clip.", session_id=session_id, filename=video_clip.filename)
    # Basic validation for video content type
    if not video_clip.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Only video files are allowed.")

    try:
        # Create the domain entity from the uploaded file
        video_file = VideoFile(
            filename=video_clip.filename,
            content_type=video_clip.content_type,
            content=await video_clip.read(),
        )
        # Create the request
        session_analysis_video_request = SessionAnalysVideoRequest(
            session_id= session_id,
            analysis_model_option= ACTIVE_MODELS_CONFIG.video_scene_extractor,  # The analysis model
            aggregation_model_option= ACTIVE_MODELS_CONFIG.video_scene_aggregator,  # The aggregator model
            media= video_file
        )
        # Add the heavy processing to a background task
        background_tasks.add_task(use_case.run_extraction_task(session_analysis_video_request, background_tasks))

        return {"status": "clip_processing_started", "session_id": session_id}
    except Exception as e:
        logger.exception("API: Error handling process-clip request.", session_id=session_id)
        raise HTTPException(status_code=500, detail=f"Error processing clip: {e}")


@router.post("/process-frame", status_code=status.HTTP_202_ACCEPTED)
async def process_frame_endpoint(
        background_tasks: BackgroundTasks,
        session_id: str = Form(...),
        image_frame: UploadFile = File(...),
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
):
    """
    Accepts a single image frame for asynchronous processing.
    It saves the frame, adds the analysis to a background task queue,
    and returns immediately.
    """
    logger.info("API: Received request to process image frame.", session_id=session_id, filename=image_frame.filename)
    # Basic validation for image content type
    if not image_frame.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Only image files are allowed.")

    try:
        # Create the domain entity from the uploaded file
        image_file = ImageFile(
            filename=image_frame.filename,
            content_type=image_frame.content_type,
            content=await image_frame.read(),
        )

        # Create the request
        session_analysis_video_request = SessionAnalysVideoRequest(
            session_id=session_id,
            analysis_model_option=ACTIVE_MODELS_CONFIG.video_scene_extractor,  # The analysis model
            aggregation_model_option=ACTIVE_MODELS_CONFIG.video_scene_aggregator,  # The aggregator model
            media=image_file
        )
        # Add the heavy processing to a background task
        background_tasks.add_task(use_case.run_extraction_task(session_analysis_video_request, background_tasks))

        return {"status": "frame_processing_started", "session_id": session_id}
    except Exception as e:
        logger.exception("API: Error handling process-frame request.", session_id=session_id)
        raise HTTPException(status_code=500, detail=f"Error processing frame: {e}")


@router.post("/query", response_model=SessionQueryResult)
async def query_session_endpoint(
        session_id: str = Form(...),
        question: str = Form(...),
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
):
    """
    Accepts a question about a specific session and returns a direct answer
    based on the session's current aggregated narrative. This is a synchronous request.
    """
    logger.info("API: Received request to query session.", session_id=session_id)

    try:
        request = SessionQueryRequest(
            session_id= session_id,
            question= question,
            model_option=ACTIVE_MODELS_CONFIG.video_scene_qa,
        )
        result = use_case.answer_question(request)
        return result
    except ValueError as e:
        # This catches the error if the session ID is not found
        logger.warning("API: Query for non-existent session.", session_id=request.session_id)
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.exception("API: Error handling query request.", session_id=request.session_id)
        raise HTTPException(status_code=500, detail=f"Error answering question: {e}")
