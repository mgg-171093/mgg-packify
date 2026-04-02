"""
Tests para POST /packages/generate
"""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient


def _base_payload(ruta: str) -> dict:
    """Payload base para generate con SQL + API IIS — formato Flutter."""
    return {
        "ticket": "MX01-274906",
        "hu_nombre": "Mejora login",
        "ambiente": "QA",
        "iteracion": "01",
        "ruta_packages": ruta,
        "componentes": [
            {
                "tipo": "sql",
                "instancias": [
                    {"base_datos": "RAWRAPSIIF", "scripts": ["init.sql"]}
                ],
            },
            {
                "tipo": "api_iis",
                "instancias": [
                    {"nombre_servicio": "WebRetailAPI"}
                ],
            },
        ],
    }


def test_generate_happy_path(client: TestClient, tmp_path: Path) -> None:
    """Genera un package con SQL + API IIS — verifica carpetas y archivos."""
    ruta = str(tmp_path)
    payload = _base_payload(ruta)

    resp = client.post("/packages/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["package_name"] == "MX01-274906-PortalRetail_QA-01"

    package_dir = Path(body["package_dir"])
    assert package_dir.exists()

    # Manual/ debe existir y contener el .docx
    manual_dir = package_dir / "Manual"
    assert manual_dir.exists()
    docx_path = manual_dir / "MX01-274906-PortalRetail_QA-01.docx"
    assert docx_path.exists()

    # Componentes/SQL y Componentes/API deben existir
    assert (package_dir / "Componentes" / "SQL").exists()
    assert (package_dir / "Componentes" / "API").exists()

    # package_meta.json se elimina tras la generación
    assert not (package_dir / "package_meta.json").exists()


def test_generate_nonexistent_ruta(client: TestClient) -> None:
    """Ruta no existente debe retornar ok=false con mensaje de error."""
    payload = _base_payload("C:\\NonExistentPath\\XXXX")

    resp = client.post("/packages/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is False
    assert "La ruta no existe" in body["error"]


def test_generate_liferay_build_no_folder(client: TestClient, tmp_path: Path) -> None:
    """liferay_build no debe crear carpeta en Componentes/."""
    payload = {
        "ticket": "MX01-TEST",
        "hu_nombre": "",
        "ambiente": "QA",
        "iteracion": "01",
        "ruta_packages": str(tmp_path),
        "componentes": [
            {
                "tipo": "liferay_build",
                "instancias": [{"build_id": "7957"}],
            },
        ],
    }

    resp = client.post("/packages/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    package_dir = Path(body["package_dir"])
    componentes_dir = package_dir / "Componentes"
    # Componentes/ no debe tener subcarpetas con LIFERAY
    if componentes_dir.exists():
        subdirs = [d.name for d in componentes_dir.iterdir() if d.is_dir()]
        assert "LIFERAY" not in subdirs


def test_generate_api_iis_and_apim_share_folder(client: TestClient, tmp_path: Path) -> None:
    """api_iis y apim deben compartir la misma carpeta API/ (sin duplicados)."""
    payload = {
        "ticket": "MX01-SHARE",
        "hu_nombre": "",
        "ambiente": "QA",
        "iteracion": "01",
        "ruta_packages": str(tmp_path),
        "componentes": [
            {
                "tipo": "api_iis",
                "instancias": [{"nombre_servicio": "ServiceA"}],
            },
            {
                "tipo": "apim",
                "instancias": [{"nombre_servicio": "ServiceB"}],
            },
        ],
    }

    resp = client.post("/packages/generate", json=payload)
    body = resp.json()
    assert body["ok"] is True

    package_dir = Path(body["package_dir"])
    componentes_dir = package_dir / "Componentes"
    assert componentes_dir.exists()

    # Solo debe existir una carpeta API (no API y API_IIS por separado)
    subdirs = [d.name for d in componentes_dir.iterdir() if d.is_dir()]
    assert subdirs.count("API") == 1


def test_generate_package_meta_in_root(client: TestClient, tmp_path: Path) -> None:
    """package_meta.json se escribe y luego se elimina tras la generación."""
    payload = _base_payload(str(tmp_path))

    resp = client.post("/packages/generate", json=payload)
    body = resp.json()
    assert body["ok"] is True

    package_dir = Path(body["package_dir"])
    # package_meta.json es eliminado tras la generación
    assert not (package_dir / "package_meta.json").exists()
    # NO debe estar en Manual/ tampoco
    assert not (package_dir / "Manual" / "package_meta.json").exists()


def test_generate_package_name_format(client: TestClient, tmp_path: Path) -> None:
    """El nombre del package debe seguir el formato canónico."""
    payload = {
        "ticket": "MX01-273779",
        "hu_nombre": "Fix crítico",
        "ambiente": "PROD",
        "iteracion": "2",   # debe ser zfill(2) → "02"
        "ruta_packages": str(tmp_path),
        "componentes": [
            {
                "tipo": "sql",
                "instancias": [{"base_datos": "DB_TEST", "scripts": []}],
            },
        ],
    }

    resp = client.post("/packages/generate", json=payload)
    body = resp.json()
    assert body["ok"] is True
    assert body["package_name"] == "MX01-273779-PortalRetail_PROD-02"


# ─────────────────────────────────────────────────────────────────────────────
# api_iis publicar tests
# ─────────────────────────────────────────────────────────────────────────────


def _api_iis_payload(ruta: str, publicar: bool) -> dict:
    """Payload mínimo con un componente api_iis."""
    return {
        "ticket": "MX01-PUBLISH",
        "hu_nombre": "",
        "ambiente": "QA",
        "iteracion": "01",
        "ruta_packages": ruta,
        "componentes": [
            {
                "tipo": "api_iis",
                "instancias": [
                    {
                        "nombre_servicio": "SvcA",
                        "publicar": publicar,
                    }
                ],
            }
        ],
    }


def test_generate_api_iis_publicar_false(client: TestClient, tmp_path: Path) -> None:
    """Con publicar=False no se intenta publicar — steps debe estar vacío."""
    payload = _api_iis_payload(str(tmp_path), publicar=False)

    resp = client.post("/packages/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["steps"] == []


def test_generate_api_iis_publicar_true_success(
    client: TestClient, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """
    Con publicar=True y publicación exitosa:
    - steps contiene una entrada con ok=True
    - la generación del package completa normalmente (ok=True)
    """
    from mgg_packgen_api.services.publish_service import PublishResult
    from mgg_packgen_api.services.options_service import OptionsManager
    from mgg_packgen_api.schemas.options import ApiIisServiceEntry, OptionsSchema
    from mgg_packgen_api import routes

    # Configurar un OptionsManager con "SvcA" en el catálogo
    options_file = tmp_path / "options.json"
    tmp_manager = OptionsManager(options_path=options_file)
    catalog_entry = ApiIisServiceEntry(nombre="SvcA", ruta=r"C:\repos\SvcA")
    tmp_manager.save(OptionsSchema(api_iis_services=[catalog_entry]))
    monkeypatch.setattr(routes.packages, "_options_manager", tmp_manager)

    # Monkeypatch publish_api_iis para devolver éxito
    mock_result = PublishResult(nombre="SvcA", ok=True, zip_path="/tmp/SvcA.zip")
    with patch(
        "mgg_packgen_api.routes.packages.publish_service.publish_api_iis",
        return_value=mock_result,
    ):
        payload = _api_iis_payload(str(tmp_path), publicar=True)
        resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    # steps debe tener una entrada
    assert len(body["steps"]) == 1
    step = body["steps"][0]
    assert step["ok"] is True
    assert "SvcA" in step["label"]


def test_generate_api_iis_publicar_true_failure(
    client: TestClient, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """
    Con publicar=True y publicación fallida:
    - respuesta sigue siendo 200 (non-fatal)
    - steps tiene entrada con ok=False y error="build failed"
    - el package (carpetas + docx) se generó igual
    """
    from mgg_packgen_api.services.publish_service import PublishResult
    from mgg_packgen_api.services.options_service import OptionsManager
    from mgg_packgen_api.schemas.options import ApiIisServiceEntry, OptionsSchema
    from mgg_packgen_api import routes

    # Configurar catálogo con "SvcA"
    options_file = tmp_path / "options.json"
    tmp_manager = OptionsManager(options_path=options_file)
    catalog_entry = ApiIisServiceEntry(nombre="SvcA", ruta=r"C:\repos\SvcA")
    tmp_manager.save(OptionsSchema(api_iis_services=[catalog_entry]))
    monkeypatch.setattr(routes.packages, "_options_manager", tmp_manager)

    # Monkeypatch publish_api_iis para devolver fallo
    mock_result = PublishResult(nombre="SvcA", ok=False, error="build failed")
    with patch(
        "mgg_packgen_api.routes.packages.publish_service.publish_api_iis",
        return_value=mock_result,
    ):
        payload = _api_iis_payload(str(tmp_path), publicar=True)
        resp = client.post("/packages/generate", json=payload)

    # Non-fatal: respuesta sigue siendo 200 con ok=True
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    # steps tiene la falla registrada
    assert len(body["steps"]) == 1
    step = body["steps"][0]
    assert step["ok"] is False
    assert step["error"] == "build failed"

    # Las carpetas y el .docx se generaron igual
    package_dir = Path(body["package_dir"])
    assert package_dir.exists()
    manual_dir = package_dir / "Manual"
    assert manual_dir.exists()
    docx_files = list(manual_dir.glob("*.docx"))
    assert len(docx_files) == 1


def test_generate_api_iis_publicar_true_not_in_catalog(
    client: TestClient, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """
    Con publicar=True pero el servicio no está en el catálogo:
    - respuesta 200 (non-fatal)
    - steps tiene entrada con ok=False y error="Servicio no encontrado en catálogo"
    """
    from mgg_packgen_api.services.options_service import OptionsManager
    from mgg_packgen_api.schemas.options import OptionsSchema
    from mgg_packgen_api import routes

    # Catálogo vacío — SvcA no existe
    options_file = tmp_path / "options.json"
    tmp_manager = OptionsManager(options_path=options_file)
    tmp_manager.save(OptionsSchema(api_iis_services=[]))
    monkeypatch.setattr(routes.packages, "_options_manager", tmp_manager)

    payload = _api_iis_payload(str(tmp_path), publicar=True)
    resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    assert len(body["steps"]) == 1
    step = body["steps"][0]
    assert step["ok"] is False
    assert "catálogo" in step["error"] or "catalogo" in step["error"].lower()


# ─────────────────────────────────────────────────────────────────────────────
# 8.1 — ZIP dest_dir test
# ─────────────────────────────────────────────────────────────────────────────


def test_zip_in_componentes(
    client: TestClient, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """
    Con publicar=True, el dest_dir pasado a publish_api_iis debe ser
    package_dir / "Componentes" / "API".
    """
    from mgg_packgen_api.services.publish_service import PublishResult
    from mgg_packgen_api.services.options_service import OptionsManager
    from mgg_packgen_api.schemas.options import ApiIisServiceEntry, OptionsSchema
    from mgg_packgen_api import routes

    # Catálogo con SvcZip
    options_file = tmp_path / "options.json"
    tmp_manager = OptionsManager(options_path=options_file)
    catalog_entry = ApiIisServiceEntry(nombre="SvcZip", ruta=r"C:\repos\SvcZip")
    tmp_manager.save(OptionsSchema(api_iis_services=[catalog_entry]))
    monkeypatch.setattr(routes.packages, "_options_manager", tmp_manager)

    captured: list[Path] = []

    def fake_publish(nombre: str, ruta: str, dest_dir: Path) -> PublishResult:
        captured.append(dest_dir)
        return PublishResult(nombre=nombre, ok=True, zip_path=str(dest_dir / f"{nombre}.zip"))

    with patch(
        "mgg_packgen_api.routes.packages.publish_service.publish_api_iis",
        side_effect=fake_publish,
    ):
        payload = {
            "ticket": "MX01-ZIP",
            "hu_nombre": "",
            "ambiente": "QA",
            "iteracion": "01",
            "ruta_packages": str(tmp_path),
            "componentes": [
                {
                    "tipo": "api_iis",
                    "instancias": [{"nombre_servicio": "SvcZip", "publicar": True}],
                }
            ],
        }
        resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    # dest_dir debe ser package_dir / "Componentes" / "API"
    assert len(captured) == 1
    package_dir = Path(body["package_dir"])
    assert captured[0] == package_dir / "Componentes" / "API"


# ─────────────────────────────────────────────────────────────────────────────
# 8.4 + 8.5 — SQL script copy tests
# ─────────────────────────────────────────────────────────────────────────────


def _sql_copy_payload(ruta_packages: str, scripts_copiar: list[bool]) -> dict:
    """Payload base para tests de copia de scripts SQL."""
    return {
        "ticket": "MX01-COPY",
        "hu_nombre": "",
        "ambiente": "QA",
        "iteracion": "01",
        "ruta_packages": ruta_packages,
        "componentes": [
            {
                "tipo": "sql",
                "instancias": [
                    {
                        "base_datos": "TESTDB",
                        "scripts": ["V001__init.sql"],
                        "scripts_copiar": scripts_copiar,
                    }
                ],
            }
        ],
    }


def test_scripts_copiar_copies_file(client: TestClient, tmp_path: Path) -> None:
    """
    Con scripts_copiar=[True] y el script presente en changes/:
    - copy_errors debe ser vacío
    - el archivo debe copiarse bajo Componentes/SQL/TESTDB/
    """
    # Estructura: tmp_path/packages/ (ruta_packages) y tmp_path/changes/ (sibling)
    packages_dir = tmp_path / "packages"
    packages_dir.mkdir()

    # Crear el script en changes/subdir/
    changes_dir = tmp_path / "changes"
    subdir = changes_dir / "subdir"
    subdir.mkdir(parents=True)
    script_file = subdir / "V001__init.sql"
    script_file.write_text("SELECT 1;", encoding="utf-8")

    payload = _sql_copy_payload(str(packages_dir), scripts_copiar=[True])
    resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["copy_errors"] == []

    # El archivo debe existir bajo Componentes/SQL/TESTDB/
    package_dir = Path(body["package_dir"])
    dest_file = package_dir / "Componentes" / "SQL" / "TESTDB" / "V001__init.sql"
    assert dest_file.exists()
    assert dest_file.read_text(encoding="utf-8") == "SELECT 1;"


def test_scripts_copiar_false_skips(client: TestClient, tmp_path: Path) -> None:
    """
    Con scripts_copiar=[False] no se copia ningún archivo — copy_errors vacío.
    """
    packages_dir = tmp_path / "packages"
    packages_dir.mkdir()

    # Script presente en changes/ pero NO debe copiarse
    changes_dir = tmp_path / "changes"
    changes_dir.mkdir()
    (changes_dir / "V001__init.sql").write_text("SELECT 2;", encoding="utf-8")

    payload = _sql_copy_payload(str(packages_dir), scripts_copiar=[False])
    resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["copy_errors"] == []

    # El archivo NO debe haberse copiado
    package_dir = Path(body["package_dir"])
    dest_file = package_dir / "Componentes" / "SQL" / "TESTDB" / "V001__init.sql"
    assert not dest_file.exists()


def test_scripts_copiar_missing_file_adds_copy_error(
    client: TestClient, tmp_path: Path
) -> None:
    """
    Con scripts_copiar=[True] pero el script no existe en changes/:
    - copy_errors debe contener una entrada con el nombre del script
    - respuesta es 200 (non-fatal)
    """
    packages_dir = tmp_path / "packages"
    packages_dir.mkdir()

    # changes/ existe pero NO contiene el script
    changes_dir = tmp_path / "changes"
    changes_dir.mkdir()
    # No creamos V001__init.sql

    payload = _sql_copy_payload(str(packages_dir), scripts_copiar=[True])
    resp = client.post("/packages/generate", json=payload)

    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True

    # Debe haber exactamente un error de copia con el nombre del script
    assert len(body["copy_errors"]) == 1
    assert "V001__init.sql" in body["copy_errors"][0]
