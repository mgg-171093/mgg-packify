"""
Ruta GET /health — health check para el SplashScreen de Flutter.
"""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class HealthResponse(BaseModel):
    status: str
    version: str


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """
    Health check endpoint.

    Returns:
        HealthResponse con status='ok' y version='3.0.0'.
    """
    return HealthResponse(status="ok", version="3.0.0")
