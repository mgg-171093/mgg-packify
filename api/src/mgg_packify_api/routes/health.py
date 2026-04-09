"""
Ruta GET /health — health check para el SplashScreen de Flutter.
"""

from __future__ import annotations

from importlib.metadata import PackageNotFoundError, version

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


def _get_version() -> str:
    """
    Devuelve la versión instalada del paquete mgg-packify-api.

    Returns:
        Versión como string (e.g. '3.5.0'), o 'unknown' si el paquete
        no está instalado (e.g. en entorno de desarrollo sin instalar).
    """
    try:
        return version("mgg-packify-api")
    except PackageNotFoundError:
        return "unknown"


class HealthResponse(BaseModel):
    status: str
    version: str


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """
    Health check endpoint.

    Returns:
        HealthResponse con status='ok' y version dinámica del paquete instalado.
    """
    return HealthResponse(status="ok", version=_get_version())
