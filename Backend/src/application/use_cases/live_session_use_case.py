import uuid
import structlog
import threading
from typing import Dict

from src.domain.entities import (
    SessionState,
    SessionQueryRequest,
    SessionQueryResult,
)
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService
from .strategies import VideoSceneExtractor, FrameSceneExtractor
from src.domain.entities.live_session import SessionAnalysVideoRequest
from ...infrastructure.prompt_loader import prompt_loader

# Get a logger instance for this module
logger = structlog.get_logger(__name__)

# --- In-Memory Session Storage (Global) ---
SESSION_STORAGE: Dict[str, SessionState] = {}
SESSION_LOCKS: Dict[str, threading.Lock] = {}


def get_session(session_id: str) -> SessionState:
    """
    Retrieves the state for a given session ID from global storage.
    """
    session = SESSION_STORAGE.get(session_id)
    if not session:
        logger.warning("Attempted to access a non-existent session.", session_id=session_id)
        raise ValueError(f"Session with ID '{session_id}' not found.")
    return session


# --- BACKGROUND TASK WORKER (Moved outside the class) ---
# This is the new, independent function for the background task.
def run_aggregation_task_worker(session_id: str, video_scene_aggregator_model: str, vision_service: VisionService):
    """
    The "consumer" part of the pipeline. It processes all pending descriptions
    in the queue for a given session. It is now a standalone function.
    """
    logger.info("Aggregation task started.", session_id=session_id)
    lock = SESSION_LOCKS.get(session_id)
    if not lock:
        return

    # Process the queue until it's empty
    while True:
        with lock:
            session = get_session(session_id)
            if not session.pending_descriptions:
                session.is_aggregator_running = False
                logger.info("Aggregation task finished as queue is empty.", session_id=session_id)
                break

            next_desc = session.pending_descriptions.pop(0)

        # --- Perform the AI call outside the lock ---
        try:
            aggregator_prompt = prompt_loader.get(
            'live_session.narrative_aggregator',
            current_narrative=session.current_narrative,
            next_desc=next_desc
            )
            new_narrative = vision_service.analyze_text(
                prompt=aggregator_prompt,
                model_option=video_scene_aggregator_model
            ).text

            # --- Re-acquire the lock to safely update the shared state ---
            with lock:
                session = get_session(session_id)
                session.current_narrative = new_narrative.strip()
                logger.info("Narrative updated.", session_id=session_id,
                            new_narrative_length=len(session.current_narrative))
        except Exception:
            logger.exception("Error during narrative aggregation.", session_id=session_id)
            with lock:
                session = get_session(session_id)
                session.pending_descriptions.insert(0, next_desc)
            break


class LiveSessionUseCase:
    """
    Orchestrates the stateful Live Session.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        self.vision_service = vision_service
        self.storage_service = storage_service
        logger.info("LiveSessionUseCase initialized")

    def create_session(self) -> str:
        session_id = str(uuid.uuid4())
        SESSION_STORAGE[session_id] = SessionState(session_id=session_id)
        SESSION_LOCKS[session_id] = threading.Lock()
        logger.info("New session created.", session_id=session_id)
        return session_id

    def run_extraction_task(self, request: SessionAnalysVideoRequest, background_tasks):
        """
        The "producer" pipeline. It saves the media and triggers the consumer task.
        """
        logger.info("Extraction task started.", session_id=request.session_id, media_type=type(request.media).__name__)
        try:
            prefix = "session_clip" if "VideoFile" in str(type(request.media)) else "session_frame"
            self.storage_service.save_file(
                file_bytes=request.media.content,
                original_filename=request.media.filename,
                prefix=prefix
            )

            if prefix == "session_clip":
                extractor = VideoSceneExtractor(vision_service=self.vision_service)
            else:
                extractor = FrameSceneExtractor(vision_service=self.vision_service)

            scene_prompt = prompt_loader.get('scene_extraction.event_description')
            scene_description = extractor.extract_scene(
                media=request.media,
                prompt=scene_prompt,
                model=request.analysis_model_option
            )
            logger.info("Scene extracted.", session_id=request.session_id, description_length=len(scene_description))

            lock = SESSION_LOCKS.get(request.session_id)
            if not lock: return
            with lock:
                session = get_session(request.session_id)
                session.pending_descriptions.append(scene_description)
                if not getattr(session, 'is_aggregator_running', False):
                    session.is_aggregator_running = True
                    logger.info("Aggregator was not running. Starting a new one.", session_id=request.session_id)

                    # --- THIS IS THE KEY CHANGE ---
                    # We now call the new top-level worker function and pass it the
                    # vision_service instance it needs to do its job.
                    background_tasks.add_task(
                        run_aggregation_task_worker,
                        request.session_id,
                        request.aggregation_model_option,
                        self.vision_service
                    )
                else:
                    logger.info("Aggregator is already running. Not starting a new one.", session_id=request.session_id)
        except Exception:
            logger.exception("An error occurred during scene extraction.", session_id=request.session_id)

    async def answer_question(self, request: SessionQueryRequest) -> SessionQueryResult:
        """
        Answers a user's question based on the most up-to-date narrative.
        """
        logger.info("Answering question for session.", session_id=request.session_id)
        lock = SESSION_LOCKS.get(request.session_id)
        if not lock:
            raise ValueError(f"Session with ID '{request.session_id}' not found.")

        with lock:
            session = get_session(request.session_id)
            current_narrative = session.current_narrative

            # 1. Get the prompt for the selected mode.
            mode_prompt = prompt_loader.get(f'prompt_mode.{request.mode.value}')

            # 2. Get the contextual QA template and render it.
            qa_prompt = prompt_loader.get(
                'live_session.contextual_qa',
                mode_prompt=mode_prompt,
                current_narrative=current_narrative,
                question=request.question
            )

        answer = self.vision_service.analyze_text(prompt=qa_prompt, model_option=request.model_option).text

        logger.info("Question answered.", session_id=request.session_id, answer_length=len(answer))
        return SessionQueryResult(session_id=request.session_id, answer=answer.strip())