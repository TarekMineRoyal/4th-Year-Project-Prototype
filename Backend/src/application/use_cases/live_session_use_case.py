import uuid
import structlog
import threading
from typing import Dict, List

from src.domain.entities import (
    MediaType,
    SessionState,
    SessionQueryRequest,
    SessionQueryResult,
)
from src.application.services.vision_service import VisionService
from src.application.services.storage_service import StorageService
from .strategies import SceneExtractorStrategy, VideoSceneExtractor, FrameSceneExtractor
from src.domain.entities.live_session import SessionAnalysVideoRequest

# Get a logger instance for this module
logger = structlog.get_logger(__name__)

# --- In-Memory Session Storage ---
# This is a simple in-memory dictionary to store session state.
# For a production application, this should be replaced with a proper database
# like Redis. The lock would be replaced with a distributed lock mechanism.
SESSION_STORAGE: Dict[str, SessionState] = {}
SESSION_LOCKS: Dict[str, threading.Lock] = {}


class LiveSessionUseCase:
    """
    Orchestrates the stateful Live Session, handling asynchronous processing
    of media frames and answering user questions against the aggregated context.
    """

    def __init__(self, vision_service: VisionService, storage_service: StorageService):
        """
        Initializes the use case with necessary services.
        """
        self.vision_service = vision_service
        self.storage_service = storage_service
        logger.info("LiveSessionUseCase initialized")

    def create_session(self) -> str:
        """
        Creates a new session, initializes its state and lock, and returns a unique session ID.
        """
        session_id = str(uuid.uuid4())
        SESSION_STORAGE[session_id] = SessionState(session_id=session_id)
        SESSION_LOCKS[session_id] = threading.Lock()  # Create a dedicated lock for the new session
        logger.info("New session created.", session_id=session_id)
        return session_id

    def get_session(self, session_id: str) -> SessionState:
        """
        Retrieves the state for a given session ID.
        """
        session = SESSION_STORAGE.get(session_id)
        if not session:
            logger.warning("Attempted to access a non-existent session.", session_id=session_id)
            raise ValueError(f"Session with ID '{session_id}' not found.")
        return session

    def _run_aggregation_task(self, session_id: str, video_scene_aggregator_model: str):
        """
        The "consumer" part of the pipeline. It processes all pending descriptions
        in the queue for a given session, ensuring order is maintained.
        """
        logger.info("Aggregation task started.", session_id=session_id, video_scene_aggregator_model= video_scene_aggregator_model)
        lock = SESSION_LOCKS.get(session_id)
        if not lock:
            return

        with lock:
            session = self.get_session(session_id)
            # This check is a safeguard, the flag should already be True
            if not getattr(session, 'is_aggregator_running', False):
                return  # Should not happen

        # Process the queue until it's empty
        while True:
            with lock:
                session = self.get_session(session_id)
                if not session.pending_descriptions:
                    # Queue is empty, work is done.
                    # Set flag to False and exit the loop.
                    session.is_aggregator_running = False
                    logger.info("Aggregation task finished as queue is empty.", session_id=session_id)
                    break  # Exit the while loop

                # Get the next item to process
                next_desc = session.pending_descriptions.pop(0)

            # --- Perform the AI call outside the lock ---
            # This allows new descriptions to be added to the queue while the AI is thinking.
            try:
                aggregator_prompt = (
                    f"The story so far is: '{session.current_narrative}'. "
                    f"The following new event just happened: '{next_desc}'. "
                    "Combine these into a single, updated, coherent narrative. "
                    "Rewrite the story to naturally include the new event. Do not mention that this is an update."
                )
                new_narrative = self.vision_service.analyze_text(
                    prompt=aggregator_prompt,
                    model_option=video_scene_aggregator_model
                ).text

                # --- Re-acquire the lock to safely update the shared state ---
                with lock:
                    session = self.get_session(session_id)
                    session.current_narrative = new_narrative.strip()
                    logger.info("Narrative updated.", session_id=session_id,
                                new_narrative_length=len(session.current_narrative))

            except Exception:
                logger.exception("Error during narrative aggregation.", session_id=session_id)
                # Put the description back at the front of the queue to be retried
                with lock:
                    session = self.get_session(session_id)
                    session.pending_descriptions.insert(0, next_desc)
                break  # Stop processing on error to maintain order

    def run_extraction_task(self, request: SessionAnalysVideoRequest, background_tasks):
        """
        The "producer" pipeline. It saves the media file permanently, then extracts
        a scene description from the saved path and triggers the consumer task.
        """
        logger.info("Extraction task started.", session_id=request.session_id, media_type=type(request.media).__name__)
        try:
            # --- Step 1: Save the file to its permanent location ---
            prefix = "session_clip" if "VideoFile" in str(type(request.media)) else "session_frame"
            saved_path = self.storage_service.save_file(
                file_bytes=request.media.content,
                original_filename=request.media.filename,
                prefix=prefix
            )
            logger.info("Media file saved permanently.", session_id=request.session_id, path=saved_path)

            # Assigning the extractor strategy
            extractor = VideoSceneExtractor if prefix == "session_clip" else FrameSceneExtractor

            # --- Step 2: Call Model 1 (SceneExtractor) via the strategy, using the file path ---
            scene_prompt = "Describe the events in this media concisely. Focus on actions, objects, and people."
            scene_description = extractor.extract_scene(request.media, scene_prompt, request.analysis_model_option)
            logger.info("Scene extracted.", session_id=request.session_id, description_length=len(scene_description))

            # --- Step 3: Add the result to the shared queue and check if we need to start the consumer ---
            lock = SESSION_LOCKS.get(request.session_id)
            if not lock: return
            with lock:
                session = self.get_session(request.session_id)
                session.pending_descriptions.append(scene_description)
                if not getattr(session, 'is_aggregator_running', False):
                    session.is_aggregator_running = True
                    logger.info("Aggregator was not running. Starting a new one.", session_id=request.session_id)
                    background_tasks.add_task(self._run_aggregation_task, request.session_id)
                else:
                    logger.info("Aggregator is already running. Not starting a new one.", session_id=request.session_id)
        except Exception:
            logger.exception("An error occurred during scene extraction.", session_id=request.session_id)

    def answer_question(self, request: SessionQueryRequest) -> SessionQueryResult:
        """
        Answers a user's question based on the most up-to-date narrative context of a session.
        This method is thread-safe.
        """
        logger.info("Answering question for session.", session_id=request.session_id)

        lock = SESSION_LOCKS.get(request.session_id)
        if not lock:
            raise ValueError(f"Session with ID '{request.session_id}' not found.")

        # Acquire the lock before reading the shared narrative
        with lock:
            session = self.get_session(request.session_id)
            current_narrative = session.current_narrative

        # --- The AI call happens outside the lock ---
        # This is important so we don't block other tasks while waiting for the AI.
        qa_prompt = (
            "You are an AI assistant answering questions for a visually impaired user based on a narrative of events. "
            "Be direct and concise. Use only the provided context to answer.\n\n"
            f"Context: '{current_narrative}'\n\n"
            f"Question: '{request.question}'"
        )

        answer = self.vision_service.analyze_text(prompt=qa_prompt, model_option=request.model_option).text

        logger.info("Question answered.", session_id=request.session_id, answer_length=len(answer))
        return SessionQueryResult(answer=answer.strip())
