"""
FastAPI application entry point.

Arranca el servidor en localhost:8787 para ser lanzado como proceso hijo
por la app Flutter.
"""

from __future__ import annotations

import logging
import logging.handlers
import os
from pathlib import Path

from fastapi import FastAPI

from mgg_packify_api.routes import health, logs as logs_router, packages, settings


def _setup_logging() -> None:
    """
    Configura el root logger con RotatingFileHandler (5 MB, 3 backups)
    apuntando a %LOCALAPPDATA%\\MGG Packify\\logs\\api.log.

    También agrega un StreamHandler para desarrollo.
    """
    local_appdata = os.environ.get("LOCALAPPDATA", os.path.expanduser("~"))
    log_dir = Path(local_appdata) / "MGG Packify" / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / "api.log"

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    # File handler with rotation: 5 MB, 3 backups
    file_handler = logging.handlers.RotatingFileHandler(
        log_path,
        maxBytes=5 * 1024 * 1024,
        backupCount=3,
        encoding="utf-8",
    )
    formatter = logging.Formatter(
        "%(asctime)s %(levelname)s %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)

    # Console handler for dev
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)


_setup_logging()

app = FastAPI(
    title="MGG-Packify",
    version="3.5.0",
    description="MGG-Packify API",
)

app.include_router(health.router)
app.include_router(settings.router)
app.include_router(packages.router)
app.include_router(logs_router.router)


def start() -> None:
    """
    Arranca el servidor uvicorn en localhost:8787.

    Usado como entry point del script instalado (mgg-packify-api).
    Flutter lanza este proceso hijo al iniciar.
    """
    import uvicorn

    uvicorn.run(
        "mgg_packify_api.main:app",
        host="127.0.0.1",
        port=8787,
        reload=False,
    )


if __name__ == "__main__":
    start()
