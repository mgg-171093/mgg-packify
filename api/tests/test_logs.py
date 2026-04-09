"""
Tests para GET /logs
"""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient


def test_logs_api_source_file_not_exists(
    client: TestClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """GET /logs?source=api cuando el archivo no existe → retorna lista vacía, 200."""
    import mgg_packify_api.routes.logs as logs_module

    # Apuntar a un directorio vacío (sin api.log)
    empty_dir = tmp_path / "logs_empty"
    empty_dir.mkdir()
    monkeypatch.setattr(logs_module, "_log_dir", lambda: empty_dir)

    response = client.get("/logs?source=api&lines=50")
    assert response.status_code == 200
    body = response.json()
    assert body["lines"] == []
    assert body["source"] == "api"
    assert body["total_lines"] == 0


def test_logs_app_source_file_not_exists(
    client: TestClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """GET /logs?source=app cuando el archivo no existe → retorna lista vacía, 200."""
    import mgg_packify_api.routes.logs as logs_module

    empty_dir = tmp_path / "logs_empty"
    empty_dir.mkdir()
    monkeypatch.setattr(logs_module, "_log_dir", lambda: empty_dir)

    response = client.get("/logs?source=app&lines=50")
    assert response.status_code == 200
    body = response.json()
    assert body["lines"] == []
    assert body["source"] == "app"
    assert body["total_lines"] == 0


def test_logs_api_source_with_existing_file(
    client: TestClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """GET /logs?source=api con archivo existente → retorna las líneas correctas."""
    import mgg_packify_api.routes.logs as logs_module

    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    log_file = log_dir / "api.log"
    log_file.write_text("linea1\nlinea2\nlinea3\n", encoding="utf-8")

    monkeypatch.setattr(logs_module, "_log_dir", lambda: log_dir)

    response = client.get("/logs?source=api&lines=50")
    assert response.status_code == 200
    body = response.json()
    assert body["lines"] == ["linea1", "linea2", "linea3"]
    assert body["source"] == "api"
    assert body["total_lines"] == 3


def test_logs_invalid_source_handled_gracefully(client: TestClient) -> None:
    """GET /logs?source=invalid → retorna lista vacía sin error, 200."""
    response = client.get("/logs?source=invalid&lines=50")
    assert response.status_code == 200
    body = response.json()
    assert body["lines"] == []
    assert body["source"] == "invalid"
    assert body["total_lines"] == 0


def test_logs_lines_zero_returns_422(client: TestClient) -> None:
    """GET /logs?source=api&lines=0 → 422 por validación FastAPI (ge=1)."""
    response = client.get("/logs?source=api&lines=0")
    assert response.status_code == 422


def test_logs_large_n_returns_all_lines(
    client: TestClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """GET /logs?source=api&lines=9999 con pocas líneas → retorna todas sin error."""
    import mgg_packify_api.routes.logs as logs_module

    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    log_file = log_dir / "api.log"
    content = "\n".join(f"linea{i}" for i in range(1, 6)) + "\n"
    log_file.write_text(content, encoding="utf-8")

    monkeypatch.setattr(logs_module, "_log_dir", lambda: log_dir)

    response = client.get("/logs?source=api&lines=9999")
    assert response.status_code == 200
    body = response.json()
    assert len(body["lines"]) == 5
    assert body["total_lines"] == 5


def test_logs_returns_last_n_lines(
    client: TestClient,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """GET /logs?source=api&lines=2 con 5 líneas → retorna las últimas 2."""
    import mgg_packify_api.routes.logs as logs_module

    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    log_file = log_dir / "api.log"
    log_file.write_text(
        "primera\nsegunda\ntercera\ncuarta\nquinta\n", encoding="utf-8"
    )

    monkeypatch.setattr(logs_module, "_log_dir", lambda: log_dir)

    response = client.get("/logs?source=api&lines=2")
    assert response.status_code == 200
    body = response.json()
    assert body["lines"] == ["cuarta", "quinta"]
    assert body["total_lines"] == 5
