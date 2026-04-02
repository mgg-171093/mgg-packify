"""
Tests para _derive_component_config en routes/packages.py

REQ-TABLE-01: SQL expansion — 3 scripts → 3 ComponentConfig rows
REQ-TABLE-02: Each SQL row: CONTENEDOR=nombre_bd, estatus/tipo from inst
REQ-TABLE-03: api_iis CONTENEDOR → "IIS"
REQ-TABLE-04: api_docker CONTENEDOR → "Docker"
REQ-TABLE-05: liferay_build NOMBRE="#"+build_id / TIPO="build" / CONTENEDOR="liferay"
"""

from __future__ import annotations

import pytest

from mgg_packgen_api.routes.packages import _derive_component_config
from mgg_packgen_api.schemas.package import ArchivoItemIn, ComponentIn, InstanceIn
from mgg_packgen_api.services.component import ComponentConfig, ComponentType


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────


def _make_comp(tipo: str) -> ComponentIn:
    return ComponentIn(tipo=tipo)


def _make_inst(**kwargs) -> InstanceIn:
    return InstanceIn(**kwargs)


# ─────────────────────────────────────────────────────────────────────────────
# REQ-TABLE-01/02: SQL expansion
# ─────────────────────────────────────────────────────────────────────────────


def test_sql_three_scripts_yields_three_configs() -> None:
    """SQL con 3 scripts debe producir 3 ComponentConfig (REQ-TABLE-01)."""
    comp = _make_comp("sql")
    inst = _make_inst(
        base_datos="RAWRAPSIIF",
        scripts=["init.sql", "patch.sql", "cleanup.sql"],
        estatus="modificado",
        tipo="sp",
    )

    result = _derive_component_config(comp, inst)

    assert isinstance(result, list), "_derive_component_config debe retornar list"
    assert len(result) == 3


@pytest.mark.parametrize(
    "script",
    ["init.sql", "patch.sql", "cleanup.sql"],
)
def test_sql_each_row_has_nombre_from_script(script: str) -> None:
    """Cada fila SQL tiene nombre_display=script (REQ-TABLE-01)."""
    comp = _make_comp("sql")
    inst = _make_inst(
        base_datos="RAWRAPSIIF",
        scripts=["init.sql", "patch.sql", "cleanup.sql"],
        estatus="modificado",
        tipo="sp",
    )

    results = _derive_component_config(comp, inst)
    nombres = [c.nombre_display for c in results]
    assert script in nombres


def test_sql_contenedor_equals_nombre_bd() -> None:
    """Cada fila SQL tiene contenedor=nombre_bd (REQ-TABLE-02)."""
    comp = _make_comp("sql")
    inst = _make_inst(
        base_datos="RAWRAPSIIF",
        scripts=["a.sql", "b.sql"],
        estatus="modificado",
        tipo="sp",
    )

    results = _derive_component_config(comp, inst)

    for cfg in results:
        assert cfg.contenedor == "RAWRAPSIIF"


def test_sql_estatus_from_inst() -> None:
    """Cada fila SQL hereda estatus de inst (REQ-TABLE-02)."""
    comp = _make_comp("sql")
    inst = _make_inst(
        base_datos="DB",
        scripts=["a.sql"],
        estatus="nuevo",
        tipo="trigger",
    )

    results = _derive_component_config(comp, inst)

    assert len(results) == 1
    assert results[0].estatus == "nuevo"


def test_sql_tipo_from_inst() -> None:
    """Cada fila SQL hereda tipo de inst (REQ-TABLE-02)."""
    comp = _make_comp("sql")
    inst = _make_inst(
        base_datos="DB",
        scripts=["a.sql"],
        estatus="modificado",
        tipo="job",
    )

    results = _derive_component_config(comp, inst)

    assert len(results) == 1
    assert results[0].tipo == "job"


def test_sql_empty_scripts_yields_zero_configs() -> None:
    """SQL sin scripts produce lista vacía."""
    comp = _make_comp("sql")
    inst = _make_inst(base_datos="DB", scripts=[])

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert len(results) == 0


# ─────────────────────────────────────────────────────────────────────────────
# REQ-TABLE-03: api_iis CONTENEDOR → "IIS"
# ─────────────────────────────────────────────────────────────────────────────


def test_api_iis_contenedor_is_IIS() -> None:
    """api_iis debe tener contenedor='IIS' (REQ-TABLE-03)."""
    comp = _make_comp("api_iis")
    inst = _make_inst(nombre_servicio="WebRetailAPI")

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0].contenedor == "IIS"


# ─────────────────────────────────────────────────────────────────────────────
# REQ-TABLE-04: api_docker CONTENEDOR → "Docker"
# ─────────────────────────────────────────────────────────────────────────────


def test_api_docker_contenedor_is_Docker() -> None:
    """api_docker debe tener contenedor='Docker' (REQ-TABLE-04)."""
    comp = _make_comp("api_docker")
    inst = _make_inst(nombre_servicio="RetailDockerAPI")

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0].contenedor == "Docker"


# ─────────────────────────────────────────────────────────────────────────────
# REQ-TABLE-05: liferay_build NOMBRE="#"+build_id / TIPO="build" / CONTENEDOR="liferay"
# ─────────────────────────────────────────────────────────────────────────────


def test_liferay_build_nombre_is_hash_plus_build_id() -> None:
    """liferay_build: nombre_display='#7957' (REQ-TABLE-05)."""
    comp = _make_comp("liferay_build")
    inst = _make_inst(build_id="7957")

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert len(results) == 1
    assert results[0].nombre_display == "#7957"


def test_liferay_build_tipo_is_build() -> None:
    """liferay_build: tipo='build' (REQ-TABLE-05)."""
    comp = _make_comp("liferay_build")
    inst = _make_inst(build_id="7957")

    results = _derive_component_config(comp, inst)

    assert results[0].tipo == "build"


def test_liferay_build_contenedor_is_lowercase_liferay() -> None:
    """liferay_build: contenedor='liferay' (lowercase) (REQ-TABLE-05)."""
    comp = _make_comp("liferay_build")
    inst = _make_inst(build_id="7957")

    results = _derive_component_config(comp, inst)

    assert results[0].contenedor == "liferay"


# ─────────────────────────────────────────────────────────────────────────────
# Additional CONTENEDOR fixes
# ─────────────────────────────────────────────────────────────────────────────


def test_liferay_contenedor_is_Liferay() -> None:
    """liferay: contenedor='Liferay' (capitalized)."""
    comp = _make_comp("liferay")
    inst = _make_inst(nombre="RetailApp")

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert results[0].contenedor == "Liferay"


def test_assets_contenedor_is_Assets() -> None:
    """assets: contenedor='Assets'."""
    comp = _make_comp("assets")
    inst = _make_inst(
        archivos=[ArchivoItemIn(nombre="logo.png", carpeta="images")]
    )

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert results[0].contenedor == "Assets"


def test_apim_contenedor_is_APIM() -> None:
    """apim: contenedor='APIM'."""
    comp = _make_comp("apim")
    inst = _make_inst(nombre_servicio="RetailGateway")

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert results[0].contenedor == "APIM"


# ─────────────────────────────────────────────────────────────────────────────
# Blob expansion — N archivos → N ComponentConfig rows
# ─────────────────────────────────────────────────────────────────────────────


def test_blob_two_files_yields_two_configs() -> None:
    """blob con 2 archivos debe producir 2 ComponentConfig."""
    comp = _make_comp("blob")
    inst = _make_inst(
        archivos=[
            ArchivoItemIn(nombre="app.css", carpeta="retail"),
            ArchivoItemIn(nombre="vendor.js", carpeta="retail"),
        ],
        estatus="modificado",
        tipo="css",
    )

    results = _derive_component_config(comp, inst)

    assert isinstance(results, list)
    assert len(results) == 2


def test_blob_each_row_nombre_from_archivo() -> None:
    """Cada fila blob tiene nombre_display del archivo."""
    comp = _make_comp("blob")
    inst = _make_inst(
        archivos=[
            ArchivoItemIn(nombre="app.css", carpeta="retail"),
            ArchivoItemIn(nombre="vendor.js", carpeta="retail"),
        ],
    )

    results = _derive_component_config(comp, inst)
    nombres = [c.nombre_display for c in results]

    assert "app.css" in nombres
    assert "vendor.js" in nombres
