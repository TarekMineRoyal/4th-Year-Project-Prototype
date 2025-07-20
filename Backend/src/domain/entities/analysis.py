from pydantic import BaseModel

class AnalysisResult(BaseModel):
    """
    A generic result from any vision model analysis,
    containing the raw text output and the service's processing time.
    """
    text: str
    processing_time: float