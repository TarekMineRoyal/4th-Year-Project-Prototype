import logging
import sys
import os
import structlog

def setup_logging():
    """
    Configures the logging system based on the environment.
    """
    is_dev_env = os.getenv("ENV", "development").lower() == "development"

    # Define processors, which are functions that process log records.
    # These are shared between development and production.
    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
    ]

    if is_dev_env:
        # --- Development Logging Configuration ---
        # Human-readable, colorful logs for local development.
        log_renderer = structlog.dev.ConsoleRenderer(colors=True)
        processors = shared_processors + [
            structlog.dev.set_exc_info,
            structlog.processors.format_exc_info,
            log_renderer
        ]
    else:
        # --- Production Logging Configuration ---
        # Machine-readable JSON logs for production.
        log_renderer = structlog.processors.JSONRenderer()
        processors = shared_processors + [
            structlog.stdlib.filter_by_level,
            structlog.stdlib.render_to_log_kwargs,
            log_renderer,
        ]

    # Configure structlog itself
    structlog.configure(
        processors=processors,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Configure standard Python logging to use structlog
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=logging.INFO if not is_dev_env else logging.DEBUG,
    )

    print(f"Logging configured for '{os.getenv('ENV', 'development')}' environment.")