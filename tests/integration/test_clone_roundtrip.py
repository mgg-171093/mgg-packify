"""
Tests de integración: clone round-trip.

Verifica que el ciclo completo save_package_meta → load → crear nuevo package
con iteración incrementada funcione correctamente.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from portal_retail.core.component import ComponentConfig, ComponentType
from portal_retail.core.package import PackageConfig, ServerConfig
from portal_retail.services.doc_generator import generate_document
from portal_retail.services.folder_service import (
    create_package_folders,
    load_package_meta,
    save_package_meta,
)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _create_original_package(tmp_path: Path) -> tuple[PackageConfig, Path]:
    """Crea el package original en tmp_path y retorna config + pkg_dir."""
    config = PackageConfig(
        ticket="MX01-11111",
        hu_nombre="Package Original",
        ambiente="QA",
        iteracion="01",
        ruta_packages="",
        componentes=[
            ComponentConfig(
                tipo_clave=ComponentType.SQL,
                nombre_display="Script v1",
                tipo_display="sql",
                contenedor="QA",
                scripts=["001-init.sql"],
                base_datos="RAWRAPSIIF",
            ),
            ComponentConfig(
                tipo_clave=ComponentType.API_IIS,
                nombre_display="API v1",
                tipo_display="api_iis",
                contenedor="QA",
                nombre_servicio="PortalAPI",
            ),
        ],
        servidores=ServerConfig(api="10.0.0.1", bd="10.0.0.2"),
    )
    pkg_dir = create_package_folders(config, base_dir=tmp_path)
    doc_path = pkg_dir / "Manual" / f"{config.package_name}.docx"
    generate_document(config, doc_path)
    save_package_meta(config, pkg_dir)
    return config, pkg_dir


def _rebuild_config_from_meta(meta: dict, new_iteracion: str) -> PackageConfig:
    """Reconstruye un PackageConfig desde un dict de package_meta.json."""
    componentes = []
    for c in meta.get("componentes", []):
        comp = ComponentConfig(
            tipo_clave=ComponentType(c["tipo_clave"]),
            nombre_display=c.get("nombre_display", ""),
            tipo_display=c.get("tipo_display", ""),
            contenedor=c.get("contenedor", ""),
            estatus=c.get("estatus", "modificado"),
            scripts=c.get("scripts", []),
            base_datos=c.get("base_datos", ""),
            nombre_servicio=c.get("nombre_servicio", ""),
            configs=c.get("configs", []),
            archivos=c.get("archivos", []),
            build_id=c.get("build_id", ""),
            nombre=c.get("nombre", ""),
            tipo=c.get("tipo", ""),
            crear_pagina=c.get("crear_pagina", False),
            pagina=c.get("pagina", ""),
            widgets=c.get("widgets", []),
        )
        componentes.append(comp)

    srv_data = meta.get("servidores", {})
    servidores = ServerConfig(
        api=srv_data.get("api", ""),
        bd=srv_data.get("bd", ""),
        blob=srv_data.get("blob", ""),
        liferay=srv_data.get("liferay", ""),
    )

    return PackageConfig(
        ticket=meta["ticket"],
        hu_nombre=meta["hu_nombre"],
        ambiente=meta["ambiente"],
        iteracion=new_iteracion,
        ruta_packages=meta.get("ruta_packages", ""),
        componentes=componentes,
        servidores=servidores,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────────────────────────────────────

class TestCloneRoundtrip:

    def test_meta_json_existe_despues_de_crear(self, tmp_path):
        """Después de crear un package, package_meta.json existe en la raíz del package."""
        _, pkg_dir = _create_original_package(tmp_path)
        assert (pkg_dir / "package_meta.json").exists()

    def test_meta_json_tiene_datos_correctos(self, tmp_path):
        """El JSON serializado preserva ticket, ambiente, iteracion."""
        original_config, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        assert meta["ticket"] == original_config.ticket
        assert meta["ambiente"] == original_config.ambiente
        assert meta["iteracion"] == original_config.iteracion

    def test_clone_iteracion_incrementada(self, tmp_path):
        """Clonar con iteracion '02' → el nuevo package_name termina en '-02'."""
        _, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        cloned = _rebuild_config_from_meta(meta, new_iteracion="02")
        assert cloned.iteracion == "02"
        assert cloned.package_name.endswith("-02")

    def test_clone_genera_segundo_package(self, tmp_path):
        """El package clonado puede generarse sin error."""
        _, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        cloned = _rebuild_config_from_meta(meta, new_iteracion="02")

        # Generar en la misma base temporal
        clone_dir = create_package_folders(cloned, base_dir=tmp_path)
        doc_path = clone_dir / "Manual" / f"{cloned.package_name}.docx"

        try:
            generate_document(cloned, doc_path)
        except Exception as exc:
            pytest.fail(f"generate_document() del clone falló: {exc}")

        assert doc_path.exists()

    def test_clone_componentes_identicos(self, tmp_path):
        """El clone tiene exactamente los mismos tipos de componente que el original."""
        original_config, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        cloned = _rebuild_config_from_meta(meta, new_iteracion="02")

        original_tipos = {c.tipo_clave for c in original_config.componentes}
        cloned_tipos = {c.tipo_clave for c in cloned.componentes}

        assert original_tipos == cloned_tipos

    def test_clone_ticket_preservado(self, tmp_path):
        """El ticket del clone es idéntico al original."""
        original_config, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        cloned = _rebuild_config_from_meta(meta, new_iteracion="02")

        assert cloned.ticket == original_config.ticket
        assert cloned.ambiente == original_config.ambiente

    def test_clone_nombre_distinto_al_original(self, tmp_path):
        """Los nombres del original y el clone son distintos (iteracion diferente)."""
        original_config, pkg_dir = _create_original_package(tmp_path)
        meta_path = pkg_dir / "package_meta.json"
        meta = load_package_meta(meta_path)

        cloned = _rebuild_config_from_meta(meta, new_iteracion="02")

        assert original_config.package_name != cloned.package_name
        assert original_config.package_name.endswith("-01")
        assert cloned.package_name.endswith("-02")
