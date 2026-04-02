"""
Tests para POST /packages/clone
"""

from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient


def _create_meta(directory: Path, ticket: str = "MX01-274906",
                 iteracion: str = "01", ambiente: str = "QA") -> None:
    """Crea un package_meta.json mínimo en el directorio dado."""
    meta = {
        "ticket": ticket,
        "hu_nombre": "Test HU",
        "ambiente": ambiente,
        "iteracion": iteracion,
        "ruta_packages": str(directory.parent),
        "componentes": [
            {
                "tipo_clave": "sql",
                "nombre_display": "RAWRAPSIIF",
                "tipo_display": "SQL",
                "contenedor": "SQL",
                "estatus": "modificado",
                "scripts": ["init.sql"],
                "base_datos": "RAWRAPSIIF",
                "nombre_servicio": "",
                "configs": [],
                "archivos": [],
                "build_id": "",
                "nombre": "",
                "tipo": "",
                "crear_pagina": False,
                "pagina": "",
                "widgets": [],
            }
        ],
        "servidores": {"api": "10.0.0.1", "bd": "10.0.0.2", "blob": "", "liferay": ""},
    }
    (directory / "package_meta.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def test_clone_happy_path(client: TestClient, tmp_path: Path) -> None:
    """Clone exitoso — retorna prefill con new_iteracion."""
    package_dir = tmp_path / "MX01-274906-PortalRetail_QA-01"
    package_dir.mkdir()
    _create_meta(package_dir, iteracion="01")

    payload = {
        "source_path": str(package_dir),
        "new_iteracion": "02",
    }
    resp = client.post("/packages/clone", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["prefill"]["ticket"] == "MX01-274906"
    assert body["prefill"]["iteracion"] == "02"
    assert len(body["prefill"]["componentes"]) == 1


def test_clone_missing_meta(client: TestClient, tmp_path: Path) -> None:
    """Clone con package_meta.json ausente debe retornar ok=false."""
    package_dir = tmp_path / "SomeFolderWithNoMeta"
    package_dir.mkdir()

    payload = {
        "source_path": str(package_dir),
        "new_iteracion": "02",
    }
    resp = client.post("/packages/clone", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is False
    assert "package_meta.json" in body["error"]


def test_clone_preserves_original_components(client: TestClient, tmp_path: Path) -> None:
    """Clone debe preservar todos los componentes del package original."""
    package_dir = tmp_path / "MX01-274906-PortalRetail_QA-01"
    package_dir.mkdir()
    _create_meta(package_dir, iteracion="01")

    payload = {
        "source_path": str(package_dir),
        "new_iteracion": "03",
    }
    resp = client.post("/packages/clone", json=payload)
    body = resp.json()
    assert body["ok"] is True

    prefill = body["prefill"]
    assert prefill["iteracion"] == "03"
    assert prefill["ticket"] == "MX01-274906"
    assert prefill["ambiente"] == "QA"
    # Los componentes del original deben estar presentes
    assert len(prefill["componentes"]) == 1
    assert prefill["componentes"][0]["tipo_clave"] == "sql"
