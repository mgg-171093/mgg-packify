"""
Ruta GET /logs — lectura de archivos de log para el LogViewerScreen de Flutter.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

from fastapi import APIRouter, Query
from pydantic import BaseModel

router = APIRouter()

logger = logging.getLogger(__name__)


def _log_dir() -> Path:
    local_appdata = os.environ.get("LOCALAPPDATA", os.path.expanduser("~"))
    return Path(local_appdata) / "MGG Packify" / "logs"


class LogsResponse(BaseModel):
    lines: list[str]
    source: str
    total_lines: int


@router.get("/logs", response_model=LogsResponse)
def get_logs(
    source: str = Query(..., description="Log source: 'api' or 'app'"),
    lines: int = Query(200, ge=1, le=10000, description="Number of lines to return"),
) -> LogsResponse:
    """
    Devuelve las últimas N líneas del archivo de log especificado.

    Args:
        source: 'api' para api.log, 'app' para app.log
        lines: Número de líneas a devolver (default: 200, max: 10000)

    Returns:
        LogsResponse con las últimas N líneas, source y total_lines.
    """
    log_dir = _log_dir()

    if source == "api":
        log_path = log_dir / "api.log"
    elif source == "app":
        log_path = log_dir / "app.log"
    else:
        logger.warning("get_logs: source inválido '%s'", source)
        return LogsResponse(lines=[], source=source, total_lines=0)

    if not log_path.exists():
        logger.info("get_logs: archivo no existe: %s", log_path)
        return LogsResponse(lines=[], source=source, total_lines=0)

    try:
        with open(log_path, encoding="utf-8", errors="replace") as f:
            all_lines = f.readlines()

        # Eliminar saltos de línea finales
        all_lines = [line.rstrip("\n\r") for line in all_lines]
        total = len(all_lines)
        result_lines = all_lines[-lines:] if total > lines else all_lines

        return LogsResponse(lines=result_lines, source=source, total_lines=total)

    except OSError as exc:
        logger.exception("get_logs: error leyendo %s: %s", log_path, exc)
        return LogsResponse(lines=[], source=source, total_lines=0)
