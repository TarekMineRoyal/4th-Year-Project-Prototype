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

from src.presentation.api.dependencies import get_models_config
from src.application.use_cases.live_session_use_case import LiveSessionUseCase
from src.domain.entities import (
    ImageFile,
    VideoFile,
    SessionCreationResult,
    SessionQueryResult,
    SessionQueryRequest,
    AnalysisMode
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
        # --- Dependencies ---
        background_tasks: BackgroundTasks,
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
        models_config: dict = Depends(get_models_config),

        # --- User Inputs ---
        session_id: str = Form(...),
        video_clip: UploadFile = File(...),
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
        # --- More Robust Way to Get Forced Models ---
        extractor_config = models_config.get("video_scene_extractor", {}).get("models")
        aggregator_config = models_config.get("video_scene_aggregator", {}).get("models")

        # Ensure the config exists and has at least one model listed
        if not extractor_config or not isinstance(extractor_config, list) or not extractor_config[0]:
            logger.error("Server config error: 'video_scene_extractor' model is not defined.")
            raise HTTPException(status_code=500, detail="Server configuration error for video processing.")

        if not aggregator_config or not isinstance(aggregator_config, list) or not aggregator_config[0]:
            logger.error("Server config error: 'video_scene_aggregator' model is not defined.")
            raise HTTPException(status_code=500, detail="Server configuration error for video processing.")

        # Now we can safely access the first model
        extractor_model: str = extractor_config[0]
        aggregator_model: str = aggregator_config[0]

        # Create the domain entity from the uploaded file
        video_file = VideoFile(
            filename=video_clip.filename,
            content_type=video_clip.content_type,
            content=await video_clip.read(),
        )
        # Create the request
        session_analysis_video_request = SessionAnalysVideoRequest(
            session_id= session_id,
            analysis_model_option= extractor_model,  # The analysis model
            aggregation_model_option= aggregator_model,  # The aggregator model
            media= video_file
        )
        # Add the heavy processing to a background task
        background_tasks.add_task(use_case.run_extraction_task,session_analysis_video_request, background_tasks)

        return {"status": "clip_processing_started", "session_id": session_id}
    except Exception as e:
        logger.exception("API: Error handling process-clip request.", session_id=session_id)
        raise HTTPException(status_code=500, detail=f"Error processing clip: {e}")


@router.post("/process-frame", status_code=status.HTTP_202_ACCEPTED)
async def process_frame_endpoint(
        # --- Dependencies ---
        background_tasks: BackgroundTasks,
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
        models_config: dict = Depends(get_models_config),  # <-- Inject config

        # --- User Inputs ---
        session_id: str = Form(...),
        image_frame: UploadFile = File(...),
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
        # --- More Robust Way to Get Forced Models ---
        extractor_config = models_config.get("video_scene_extractor", {}).get("models")
        aggregator_config = models_config.get("video_scene_aggregator", {}).get("models")

        if not extractor_config or not isinstance(extractor_config, list) or not extractor_config[0]:
            logger.error("Server config error: 'video_scene_extractor' model is not defined.")
            raise HTTPException(status_code=500, detail="Server configuration error for frame processing.")

        if not aggregator_config or not isinstance(aggregator_config, list) or not aggregator_config[0]:
            logger.error("Server config error: 'video_scene_aggregator' model is not defined.")
            raise HTTPException(status_code=500, detail="Server configuration error for frame processing.")

        extractor_model: str = extractor_config[0]
        aggregator_model: str = aggregator_config[0]

        # Create the domain entity from the uploaded file
        image_file = ImageFile(
            filename=image_frame.filename,
            content_type=image_frame.content_type,
            content=await image_frame.read(),
        )

        # Create the request
        session_analysis_video_request = SessionAnalysVideoRequest(
            session_id=session_id,
            analysis_model_option=extractor_model,  # The analysis model
            aggregation_model_option=aggregator_model,  # The aggregator model
            media=image_file
        )
        # Add the heavy processing to a background task
        background_tasks.add_task(use_case.run_extraction_task, session_analysis_video_request, background_tasks)

        return {"status": "frame_processing_started", "session_id": session_id}
    except Exception as e:
        logger.exception("API: Error handling process-frame request.", session_id=session_id)
        raise HTTPException(status_code=500, detail=f"Error processing frame: {e}")


@router.post("/query", response_model=SessionQueryResult)
async def query_session_endpoint(
        # --- Dependencies ---
        use_case: LiveSessionUseCase = Depends(get_live_session_use_case),
        models_config: dict = Depends(get_models_config),  # <-- Inject config

        # --- User Inputs ---
        session_id: str = Form(...),
        question: str = Form(...),
        model_option: str = Form(...),
        mode: str = Form(...),
):
    """
    Accepts a question about a session and returns an answer.
    """
    logger.info("API: Received request to query session.", session_id=session_id)

    # --- Model Validation ---
    qa_models = models_config.get("video_scene_qa", {})
    if not qa_models.get("selectable") or model_option not in qa_models.get("models", []):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid model '{model_option}' selected for Session QA.",
        )

    # --- Mode Validation ---
    if mode.lower() == "brief":
        analysis_mode = AnalysisMode.BRIEF
    elif mode.lower() == "thorough":
        analysis_mode = AnalysisMode.THOROUGH
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid analysis mode. Must be 'brief' or 'thorough'.",
        )

    try:
        request = SessionQueryRequest(
            session_id=session_id,
            question=question,
            model_option=model_option,  # <-- Use validated user input
            mode=analysis_mode,  # <-- Use validated user input
        )
        result = await use_case.answer_question(request)
        return result
    except ValueError as e:
        # This catches the error if the session ID is not found
        logger.warning("API: Query for non-existent session.", session_id=session_id)
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.exception("API: Error handling query request.", session_id=session_id)
        raise HTTPException(status_code=500, detail=f"Error answering question: {e}")
