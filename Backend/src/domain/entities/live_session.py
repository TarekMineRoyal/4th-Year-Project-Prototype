# In src/domain/entities/live_session.py
from pydantic import BaseModel
from typing import List, Union

from .documents import AnalysisMode
from .video import VideoFile
from .image import ImageFile

# A union type representing either input media
MediaType = Union[VideoFile, ImageFile]

# INPUT for the /query endpoint
class SessionQueryRequest(BaseModel):
    session_id: str
    question: str
    model_option: str
    mode: AnalysisMode

# OUTPUT for the /start endpoint
class SessionCreationResult(BaseModel):
    session_id: str

# OUTPUT for the /query endpoint
class SessionQueryResult(BaseModel):
    session_id: str
    answer: str

# Internal model for storing session state
class SessionState(BaseModel):
    session_id: str
    pending_descriptions: List[str] = []
    current_narrative: str = "The scene has just begun. This is the first item to analys."
    is_aggregator_running: bool = False

# INPUT for the /process-clip, /process-frame endpoints
class SessionAnalysVideoRequest(BaseModel):
    session_id: str
    analysis_model_option: str # The analysis model
    aggregation_model_option: str # The aggregator model
    media: MediaType # Might be a frame or a video
