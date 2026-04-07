"""
Tests para create_package_folders() en folder_service.py

REQ-FOLD-SQL: Las subcarpetas de SQL se crean por base de datos.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from mgg_packify_api.services.component import ComponentConfig, ComponentType
from mgg_packify_api.services.folder_service import create_package_folders
from mgg_packify_api.services.package import PackageConfig


def _make_sql_config(
    base_datos: str,
    script: str = "script.sql",
) -> ComponentConfig:
    """Crea un ComponentConfig de tipo SQL con una base de datos dada."""
    return ComponentConfig(
        tipo_clave=ComponentType.SQL,
        nombre_display=script,
        tipo_display="SQL",
        contenedor=base_datos,
        estatus="modificado",
        scripts=[script],
        base_datos=base_datos,
    )


# ─────────────────────────────────────────────────────────────────────────────
# 8.3 — SQL subfolders per base de datos
# ─────────────────────────────────────────────────────────────────────────────


def test_sql_subfolder_per_bd(tmp_path: Path) -> None:
    """
    create_package_folders() debe crear una subcarpeta por cada base_datos
    distinta en los componentes SQL.

    Dado un PackageConfig con dos ComponentConfig SQL (RAWRAPS y SCADB),
    deben existir:
      - Componentes/SQL/RAWRAPS/
      - Componentes/SQL/SCADB/
    """
    comp_rawraps = _make_sql_config(base_datos="RAWRAPS", script="V001__init.sql")
    comp_scadb = _make_sql_config(base_datos="SCADB", script="V002__tables.sql")

    config = PackageConfig(
        ticket="MX01-TEST",
        hu_nombre="SQL subfolder test",
        ambiente="QA",
        iteracion="01",
        ruta_packages="",  # no usado cuando se pasa base_dir
        componentes=[comp_rawraps, comp_scadb],
    )

    package_dir = create_package_folders(config, base_dir=tmp_path)

    rawraps_dir = package_dir / "Componentes" / "SQL" / "RAWRAPS"
    scadb_dir = package_dir / "Componentes" / "SQL" / "SCADB"

    assert rawraps_dir.exists(), f"Se esperaba {rawraps_dir}"
    assert scadb_dir.exists(), f"Se esperaba {scadb_dir}"
