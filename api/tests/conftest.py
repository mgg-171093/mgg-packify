"""
Fixtures compartidas para tests de mgg-packify-api.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from mgg_packify_api.main import app
from mgg_packify_api import routes


@pytest.fixture
def client() -> TestClient:
    """TestClient de FastAPI — no requiere servidor real."""
    with TestClient(app) as c:
        yield c


@pytest.fixture
def tmp_settings(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """
    Crea un SettingsManager temporal con config en tmp_path.

    Monkeypatcha el singleton _manager en routes.settings para que los tests
    de settings no escriban al %APPDATA% real.
    """
    from mgg_packify_api.services.settings_service import SettingsManager

    config_file = tmp_path / "config.json"
    tmp_manager = SettingsManager(config_path=config_file)

    # Reemplazar el singleton en el módulo de routes
    monkeypatch.setattr(routes.settings, "_manager", tmp_manager)

    return config_file
