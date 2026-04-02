"""
Tests para GET /settings y PUT /settings
"""

from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient


def test_get_settings_defaults_on_no_file(client: TestClient, tmp_settings: Path) -> None:
    """GET /settings debe retornar defaults cuando no existe config.json."""
    response = client.get("/settings")
    assert response.status_code == 200
    body = response.json()
    assert body["servers"]["qa"]["api"] == ""
    assert body["servers"]["prod"]["api"] == ""
    assert body["last_used"]["ambiente"] == "QA"
    assert body["last_used"]["iteracion"] == "01"
    assert body["last_used"]["ruta_packages"] == ""


def test_put_settings_saves_and_retrieves(client: TestClient, tmp_settings: Path) -> None:
    """PUT /settings y GET /settings deben round-trip correctamente."""
    payload = {
        "servers": {
            "qa":   {"api": "10.42.55.25", "bd": "10.42.55.30", "blob": "", "liferay": ""},
            "prod": {"api": "", "bd": "", "blob": "", "liferay": ""},
        },
        "last_used": {
            "ticket": "MX01-274906",
            "hu_nombre": "Mejora login",
            "ambiente": "QA",
            "iteracion": "01",
            "ruta_packages": "C:\\Packages",
        },
    }
    put_resp = client.put("/settings", json=payload)
    assert put_resp.status_code == 200
    assert put_resp.json()["ok"] is True

    get_resp = client.get("/settings")
    body = get_resp.json()
    assert body["servers"]["qa"]["api"] == "10.42.55.25"
    assert body["servers"]["qa"]["bd"] == "10.42.55.30"
    assert body["last_used"]["ticket"] == "MX01-274906"
    assert body["last_used"]["ruta_packages"] == "C:\\Packages"


def test_put_qa_does_not_overwrite_prod(client: TestClient, tmp_settings: Path) -> None:
    """Guardar QA no debe sobreescribir los servidores PROD."""
    # Primero guardar PROD
    setup_payload = {
        "servers": {
            "qa":   {"api": "", "bd": "", "blob": "", "liferay": ""},
            "prod": {"api": "192.168.1.1", "bd": "192.168.1.2", "blob": "", "liferay": ""},
        },
        "last_used": {
            "ticket": "", "hu_nombre": "", "ambiente": "QA",
            "iteracion": "01", "ruta_packages": "",
        },
    }
    client.put("/settings", json=setup_payload)

    # Luego actualizar solo QA
    qa_payload = {
        "servers": {
            "qa":   {"api": "10.0.0.1", "bd": "", "blob": "", "liferay": ""},
            "prod": {"api": "192.168.1.1", "bd": "192.168.1.2", "blob": "", "liferay": ""},
        },
        "last_used": {
            "ticket": "", "hu_nombre": "", "ambiente": "QA",
            "iteracion": "01", "ruta_packages": "",
        },
    }
    client.put("/settings", json=qa_payload)

    get_resp = client.get("/settings")
    body = get_resp.json()
    assert body["servers"]["qa"]["api"] == "10.0.0.1"
    assert body["servers"]["prod"]["api"] == "192.168.1.1"


def test_last_used_ruta_packages_persisted(client: TestClient, tmp_settings: Path) -> None:
    """ruta_packages en last_used debe persistirse (v3 — no hu_carpeta/tipo_carpeta)."""
    payload = {
        "servers": {
            "qa":   {"api": "", "bd": "", "blob": "", "liferay": ""},
            "prod": {"api": "", "bd": "", "blob": "", "liferay": ""},
        },
        "last_used": {
            "ticket": "MX01-999",
            "hu_nombre": "",
            "ambiente": "PROD",
            "iteracion": "02",
            "ruta_packages": "D:\\Drive\\Packages",
        },
    }
    client.put("/settings", json=payload)
    body = client.get("/settings").json()
    assert body["last_used"]["ruta_packages"] == "D:\\Drive\\Packages"
    assert body["last_used"]["iteracion"] == "02"
    assert body["last_used"]["ambiente"] == "PROD"


def test_get_settings_returns_defaults_on_corrupt_file(
    client: TestClient, tmp_settings: Path
) -> None:
    """GET /settings debe retornar defaults si config.json está corrupto."""
    # Crear un config.json corrupto
    tmp_settings.parent.mkdir(parents=True, exist_ok=True)
    tmp_settings.write_text("not valid json {{{", encoding="utf-8")

    response = client.get("/settings")
    assert response.status_code == 200
    body = response.json()
    # Debe retornar defaults silenciosamente
    assert body["servers"]["qa"]["api"] == ""
    assert body["last_used"]["ambiente"] == "QA"
