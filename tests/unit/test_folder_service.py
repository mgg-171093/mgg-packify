"""
Tests unitarios para folder_service.

Verifica que create_package_folders() cree la estructura correcta de
directorios y que save_package_meta / load_package_meta hagan round-trip.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from portal_retail.core.component import ComponentConfig, ComponentType
from portal_retail.core.package import PackageConfig, ServerConfig
from portal_retail.services.folder_service import (
    create_package_folders,
    load_package_meta,
    save_package_meta,
)

# ─────────────────────────────────────────────────────────────────────────────
# Fixtures
# ─────────────────────────────────────────────────────────────────────────────

def _sql_component() -> ComponentConfig:
    return ComponentConfig(
        tipo_clave=ComponentType.SQL,
        nombre_display="Script Inicial",
        tipo_display="sql",
        contenedor="QA",
        scripts=["init.sql"],
        base_datos="RAWRAPSIIF",
    )


def _api_component() -> ComponentConfig:
    return ComponentConfig(
        tipo_clave=ComponentType.API_IIS,
        nombre_display="Portal API",
        tipo_display="api_iis",
        contenedor="QA",
        nombre_servicio="PortalAPI",
    )


def _blob_component() -> ComponentConfig:
    return ComponentConfig(
        tipo_clave=ComponentType.BLOB,
        nombre_display="portal-ui.js",
        tipo_display="blob",
        contenedor="QA",
        archivos=[{"nombre": "portal-ui.js", "carpeta": "portal-assets"}],
    )


def _make_config(tmp_path: Path, componentes: list[ComponentConfig]) -> PackageConfig:
    return PackageConfig(
        ticket="MX01-12345",
        hu_nombre="Test HU",
        ambiente="QA",
        iteracion="01",
        ruta_packages="",
        componentes=componentes,
        servidores=ServerConfig(),
    )


# ─────────────────────────────────────────────────────────────────────────────
# Tests: create_package_folders
# ─────────────────────────────────────────────────────────────────────────────

class TestCreatePackageFolders:

    def test_sql_crea_carpeta_sql(self, tmp_path: Path):
        """1 componente SQL → Componentes/SQL/ debe existir."""
        config = _make_config(tmp_path, [_sql_component()])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)

        assert (pkg_dir / "Componentes" / "SQL").exists()
        assert (pkg_dir / "Manual").exists()

    def test_tres_componentes_crean_tres_carpetas(self, tmp_path: Path):
        """SQL + API IIS + BLOB → 3 subcarpetas distintas."""
        config = _make_config(tmp_path, [_sql_component(), _api_component(), _blob_component()])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)

        assert (pkg_dir / "Componentes" / "SQL").exists()
        assert (pkg_dir / "Componentes" / "API").exists()
        assert (pkg_dir / "Componentes" / "BLOB STORAGE").exists()

    def test_manual_siempre_existe(self, tmp_path: Path):
        """Manual/ se crea siempre, incluso con 0 componentes."""
        config = _make_config(tmp_path, [])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)

        assert (pkg_dir / "Manual").exists()
        assert pkg_dir.name == "MX01-12345-PortalRetail_QA-01"

    def test_carpetas_duplicadas_no_se_repiten(self, tmp_path: Path):
        """api_iis y apim van ambas a Componentes/API/ — sin duplicar."""
        apim = ComponentConfig(
            tipo_clave=ComponentType.APIM,
            nombre_display="API MGMT",
            tipo_display="apim",
            contenedor="QA",
        )
        config = _make_config(tmp_path, [_api_component(), apim])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)

        componentes_dir = pkg_dir / "Componentes"
        api_dirs = [d for d in componentes_dir.iterdir() if d.is_dir() and d.name == "API"]
        assert len(api_dirs) == 1

    def test_nombre_carpeta_usa_package_name(self, tmp_path: Path):
        """El directorio raíz tiene el nombre correcto."""
        config = _make_config(tmp_path, [_sql_component()])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)

        assert pkg_dir.name == config.package_name


# ─────────────────────────────────────────────────────────────────────────────
# Tests: save / load package_meta (round-trip)
# ─────────────────────────────────────────────────────────────────────────────

class TestPackageMeta:

    def test_round_trip_json(self, tmp_path: Path):
        """save_package_meta → load_package_meta devuelve datos idénticos."""
        config = _make_config(tmp_path, [_sql_component()])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)
        meta_path = save_package_meta(config, pkg_dir)

        assert meta_path.exists()
        loaded = load_package_meta(meta_path)

        assert loaded["ticket"] == "MX01-12345"
        assert loaded["ambiente"] == "QA"
        assert loaded["iteracion"] == "01"

    def test_componentes_guardados_en_meta(self, tmp_path: Path):
        """Los componentes se serializan correctamente en el JSON."""
        config = _make_config(tmp_path, [_sql_component(), _api_component()])
        pkg_dir = create_package_folders(config, base_dir=tmp_path)
        meta_path = save_package_meta(config, pkg_dir)
        loaded = load_package_meta(meta_path)

        tipos = [c["tipo_clave"] for c in loaded["componentes"]]
        assert "sql" in tipos
        assert "api_iis" in tipos

    def test_meta_no_existente_lanza_file_not_found(self, tmp_path: Path):
        """load_package_meta lanza FileNotFoundError si el archivo no existe."""
        with pytest.raises(FileNotFoundError):
            load_package_meta(tmp_path / "nonexistent" / "package_meta.json")
