# In: presentation/logging_middleware.py

import time
import uuid
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

# Get a logger instance
logger = structlog.get_logger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # 1. Generate a unique Request ID
        request_id = str(uuid.uuid4())

        # 2. Clear and bind context variables for structlog
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)

        start_time = time.time()

        # 3. Log the start of the request
        logger.info(
            "Request started",
            method=request.method,
            path=request.url.path,
            client=request.client.host
        )

        try:
            response = await call_next(request)
            process_time = time.time() - start_time

            # 4. Log the end of the request
            logger.info(
                "Request finished",
                status_code=response.status_code,
                process_time=round(process_time, 4)
            )
            response.headers["X-Request-ID"] = request_id
            return response

        except Exception as e:
            # 5. Log any unhandled exceptions
            logger.exception("Unhandled exception during request")
            raise e