"""
Tests para GET /settings/options y PUT /settings/options

REQ-OPT-01: GET returns defaults when options.json missing
REQ-OPT-02: PUT persists; subsequent GET returns updated list
REQ-OPT-03: api_iis_services CRUD
REQ-OPT-04: api_docker_services CRUD
REQ-OPT-05: v1 → v2 migration (missing keys default to [])
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def tmp_options(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """
    Crea un OptionsManager temporal con opciones en tmp_path.

    Monkeypatcha el singleton _options_manager en routes.settings para que
    los tests de options no escriban al %APPDATA% real.
    """
    from mgg_packify_api.services.options_service import OptionsManager
    from mgg_packify_api import routes

    options_file = tmp_path / "options.json"
    tmp_manager = OptionsManager(options_path=options_file)

    monkeypatch.setattr(routes.settings, "_options_manager", tmp_manager)

    return options_file


def test_get_options_defaults_on_no_file(client: TestClient, tmp_options: Path) -> None:
    """GET /settings/options debe retornar defaults cuando no existe options.json (REQ-OPT-01)."""
    assert not tmp_options.exists()

    response = client.get("/settings/options")
    assert response.status_code == 200
    body = response.json()

    assert body["estatus_options"] == ["modificado", "nuevo"]
    assert body["tipo_sql_options"] == ["sp", "trigger", "script", "job"]
    assert body["tipo_blob_options"] == ["css", "scss", "js"]


def test_put_options_persists_and_get_returns_updated(
    client: TestClient, tmp_options: Path
) -> None:
    """PUT /settings/options persiste; GET subsecuente devuelve la lista actualizada (REQ-OPT-02)."""
    payload = {
        "estatus_options": ["modificado", "nuevo", "eliminado"],
        "tipo_sql_options": ["sp", "trigger"],
        "tipo_blob_options": ["css", "js", "ts"],
    }

    put_resp = client.put("/settings/options", json=payload)
    assert put_resp.status_code == 200
    put_body = put_resp.json()
    assert put_body["estatus_options"] == ["modificado", "nuevo", "eliminado"]
    assert put_body["tipo_sql_options"] == ["sp", "trigger"]
    assert put_body["tipo_blob_options"] == ["css", "js", "ts"]

    # El archivo debe haberse creado
    assert tmp_options.exists()

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    get_body = get_resp.json()
    assert get_body["estatus_options"] == ["modificado", "nuevo", "eliminado"]
    assert get_body["tipo_sql_options"] == ["sp", "trigger"]
    assert get_body["tipo_blob_options"] == ["css", "js", "ts"]


def test_save_and_get_api_iis_services(
    client: TestClient, tmp_options: Path
) -> None:
    """PUT con api_iis_services persiste; GET devuelve la entrada (REQ-OPT-03)."""
    payload = {
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [
            {"nombre": "SvcA", "ruta": r"C:\code\SvcA\SvcA.csproj"}
        ],
        "api_docker_services": [],
    }

    put_resp = client.put("/settings/options", json=payload)
    assert put_resp.status_code == 200

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    body = get_resp.json()

    assert "api_iis_services" in body
    assert len(body["api_iis_services"]) == 1
    assert body["api_iis_services"][0]["nombre"] == "SvcA"
    assert body["api_iis_services"][0]["ruta"] == r"C:\code\SvcA\SvcA.csproj"


def test_save_and_get_api_docker_services(
    client: TestClient, tmp_options: Path
) -> None:
    """PUT con api_docker_services persiste; GET devuelve la entrada (REQ-OPT-04)."""
    payload = {
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [],
        "api_docker_services": [
            {"nombre": "DockerSvc"}
        ],
    }

    put_resp = client.put("/settings/options", json=payload)
    assert put_resp.status_code == 200

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    body = get_resp.json()

    assert "api_docker_services" in body
    assert len(body["api_docker_services"]) == 1
    assert body["api_docker_services"][0]["nombre"] == "DockerSvc"


def test_delete_api_iis_service(
    client: TestClient, tmp_options: Path
) -> None:
    """Guardar lista vacía de api_iis_services elimina todas las entradas."""
    # Primero agregar una entrada
    payload_with = {
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [
            {"nombre": "SvcToDelete", "ruta": r"C:\repos\SvcToDelete\SvcToDelete.csproj"}
        ],
        "api_docker_services": [],
    }
    client.put("/settings/options", json=payload_with)

    # Verificar que está guardado
    get_resp = client.get("/settings/options")
    assert len(get_resp.json()["api_iis_services"]) == 1

    # Ahora guardar con lista vacía (= eliminar)
    payload_empty = {
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [],
        "api_docker_services": [],
    }
    del_resp = client.put("/settings/options", json=payload_empty)
    assert del_resp.status_code == 200

    get_resp2 = client.get("/settings/options")
    assert get_resp2.status_code == 200
    assert get_resp2.json()["api_iis_services"] == []


def test_options_v1_to_v2_migration(
    client: TestClient, tmp_options: Path
) -> None:
    """
    Un options.json en formato v1 (sin api_iis_services / api_docker_services)
    se lee sin crash y ambos campos defaultean a [] (REQ-OPT-05).
    """
    # Escribir un options.json en formato v1 (sin los nuevos campos)
    v1_data = {
        "version": 1,
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
    }
    tmp_options.parent.mkdir(parents=True, exist_ok=True)
    tmp_options.write_text(json.dumps(v1_data), encoding="utf-8")

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    body = get_resp.json()

    # Los campos nuevos deben defaultear a lista vacía — sin crash
    assert body["api_iis_services"] == []
    assert body["api_docker_services"] == []
    # Los campos existentes deben seguir funcionando
    assert body["estatus_options"] == ["modificado", "nuevo"]


# ─────────────────────────────────────────────────────────────────────────────
# 8.2 — sql_databases round-trip + v2→v3 migration
# ─────────────────────────────────────────────────────────────────────────────


def test_save_and_get_sql_databases(
    client: TestClient, tmp_options: Path
) -> None:
    """
    PUT con sql_databases persiste; GET subsecuente devuelve la lista actualizada.
    """
    payload = {
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [],
        "api_docker_services": [],
        "sql_databases": ["RAWRAPS", "SCADB"],
    }

    put_resp = client.put("/settings/options", json=payload)
    assert put_resp.status_code == 200
    put_body = put_resp.json()
    assert put_body["sql_databases"] == ["RAWRAPS", "SCADB"]

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    get_body = get_resp.json()
    assert get_body["sql_databases"] == ["RAWRAPS", "SCADB"]


def test_options_v2_to_v3_migration(
    client: TestClient, tmp_options: Path
) -> None:
    """
    Un options.json en formato v2 (sin sql_databases) se lee sin crash y
    sql_databases defaultea a [].
    """
    # Escribir un options.json en formato v2 (sin sql_databases)
    v2_data = {
        "version": 2,
        "estatus_options": ["modificado", "nuevo"],
        "tipo_sql_options": ["sp", "trigger", "script", "job"],
        "tipo_blob_options": ["css", "scss", "js"],
        "api_iis_services": [],
        "api_docker_services": [],
    }
    tmp_options.parent.mkdir(parents=True, exist_ok=True)
    tmp_options.write_text(json.dumps(v2_data), encoding="utf-8")

    get_resp = client.get("/settings/options")
    assert get_resp.status_code == 200
    body = get_resp.json()

    # sql_databases debe defaultear a [] — sin crash
    assert body["sql_databases"] == []
    # Los campos existentes deben seguir funcionando
    assert body["estatus_options"] == ["modificado", "nuevo"]
    assert body["api_iis_services"] == []
