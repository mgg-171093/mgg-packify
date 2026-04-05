"""
FastAPI application entry point.

Arranca el servidor en localhost:8787 para ser lanzado como proceso hijo
por la app Flutter.
"""

from __future__ import annotations

from fastapi import FastAPI

from mgg_packgen_api.routes import health, packages, settings

app = FastAPI(
    title="MGG-Packify",
    version="3.0.0",
    description="MGG-Packify API",
)

app.include_router(health.router)
app.include_router(settings.router)
app.include_router(packages.router)


def start() -> None:
    """
    Arranca el servidor uvicorn en localhost:8787.

    Usado como entry point del script instalado (mgg-packgen-api).
    Flutter lanza este proceso hijo al iniciar.
    """
    import uvicorn

    uvicorn.run(
        "mgg_packgen_api.main:app",
        host="127.0.0.1",
        port=8787,
        reload=False,
    )


if __name__ == "__main__":
    start()
