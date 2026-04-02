"""
Tests para GET /packages/list
"""

from __future__ import annotations

import json
import time
from pathlib import Path

from fastapi.testclient import TestClient


def test_list_packages_with_and_without_meta(client: TestClient, tmp_path: Path) -> None:
    """Lista packages — distingue los que tienen package_meta.json."""
    # Crear dos carpetas
    pkg1 = tmp_path / "MX01-274906-PortalRetail_QA-01"
    pkg1.mkdir()
    (pkg1 / "package_meta.json").write_text('{"ticket": "MX01-274906"}', encoding="utf-8")

    pkg2 = tmp_path / "MX01-999-PortalRetail_QA-02"
    pkg2.mkdir()
    # Sin package_meta.json

    resp = client.get(f"/packages/list?base_dir={tmp_path}")
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["packages"]) == 2

    names = {p["name"]: p for p in body["packages"]}
    assert names["MX01-274906-PortalRetail_QA-01"]["has_meta"] is True
    assert names["MX01-999-PortalRetail_QA-02"]["has_meta"] is False


def test_list_packages_nonexistent_base_dir(client: TestClient) -> None:
    """base_dir inexistente debe retornar lista vacía sin error."""
    resp = client.get("/packages/list?base_dir=C:\\NonExistentDir\\XXXX")
    assert resp.status_code == 200
    body = resp.json()
    assert body["packages"] == []


def test_list_packages_created_at_is_iso(client: TestClient, tmp_path: Path) -> None:
    """created_at debe ser un string ISO 8601 válido."""
    pkg = tmp_path / "SomePackage"
    pkg.mkdir()

    resp = client.get(f"/packages/list?base_dir={tmp_path}")
    body = resp.json()
    assert len(body["packages"]) == 1

    from datetime import datetime
    created_at = body["packages"][0]["created_at"]
    # Debe parsear sin error como ISO datetime
    parsed = datetime.fromisoformat(created_at)
    assert parsed is not None
