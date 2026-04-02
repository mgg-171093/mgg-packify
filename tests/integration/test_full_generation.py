"""
Tests de integración: flujo completo de generación de package.

Verifica que el flujo completo (crear carpetas + generar .docx) funcione
end-to-end con un PackageConfig completo (3 componentes).
"""

from __future__ import annotations

import pytest
from docx import Document

from portal_retail.core.component import ComponentConfig, ComponentType
from portal_retail.core.package import PackageConfig, ServerConfig
from portal_retail.services.doc_generator import generate_document
from portal_retail.services.folder_service import create_package_folders, save_package_meta

# ─────────────────────────────────────────────────────────────────────────────
# Fixture: PackageConfig completo con 3 componentes
# ─────────────────────────────────────────────────────────────────────────────

@pytest.fixture
def config_tres_componentes() -> PackageConfig:
    """PackageConfig con SQL + API IIS + Blob Storage."""
    return PackageConfig(
        ticket="MX01-55555",
        hu_nombre="Integración Test",
        ambiente="QA",
        iteracion="01",
        componentes=[
            ComponentConfig(
                tipo_clave=ComponentType.SQL,
                nombre_display="Script SQL",
                tipo_display="sql",
                contenedor="QA",
                scripts=["001-schema.sql", "002-data.sql"],
                base_datos="DB_PORTAL",
            ),
            ComponentConfig(
                tipo_clave=ComponentType.API_IIS,
                nombre_display="API Portal",
                tipo_display="api_iis",
                contenedor="QA",
                nombre_servicio="Portal.API",
            ),
            ComponentConfig(
                tipo_clave=ComponentType.BLOB,
                nombre_display="Portal CSS",
                tipo_display="blob",
                contenedor="QA",
                archivos=[
                    {"nombre": "portal.css", "carpeta": "portal-ui"},
                    {"nombre": "portal.js", "carpeta": "portal-ui"},
                ],
            ),
        ],
        servidores=ServerConfig(
            api="10.0.1.1",
            bd="10.0.1.2",
            blob="myaccount.blob.core.windows.net",
            liferay="",
        ),
    )


# ─────────────────────────────────────────────────────────────────────────────
# Tests de integración
# ─────────────────────────────────────────────────────────────────────────────

class TestFullGeneration:

    def test_carpeta_package_existe(self, config_tres_componentes, tmp_path):
        """create_package_folders() crea el directorio raíz del package."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
        assert pkg_dir.exists()
        assert pkg_dir.name == config_tres_componentes.package_name

    def test_tres_subcarpetas_creadas(self, config_tres_componentes, tmp_path):
        """Las 3 subcarpetas de componentes se crean correctamente."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)

        assert (pkg_dir / "Componentes" / "SQL").exists()
        assert (pkg_dir / "Componentes" / "API").exists()
        assert (pkg_dir / "Componentes" / "BLOB STORAGE").exists()

    def test_manual_dir_creado(self, config_tres_componentes, tmp_path):
        """El directorio Manual/ se crea siempre."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
        assert (pkg_dir / "Manual").exists()

    def test_docx_generado_en_manual(self, config_tres_componentes, tmp_path):
        """generate_document() crea el .docx dentro de Manual/."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
        doc_path = pkg_dir / "Manual" / f"{config_tres_componentes.package_name}.docx"
        generate_document(config_tres_componentes, doc_path)

        assert doc_path.exists()
        assert doc_path.stat().st_size > 0

    def test_docx_valido(self, config_tres_componentes, tmp_path):
        """El .docx generado puede abrirse con python-docx."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
        doc_path = pkg_dir / "Manual" / f"{config_tres_componentes.package_name}.docx"
        generate_document(config_tres_componentes, doc_path)

        doc = Document(str(doc_path))
        assert len(doc.paragraphs) > 5

    def test_meta_json_guardado(self, config_tres_componentes, tmp_path):
        """save_package_meta() guarda package_meta.json en la raíz del package."""
        pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
        meta_path = save_package_meta(config_tres_componentes, pkg_dir)

        assert meta_path.exists()
        assert meta_path.name == "package_meta.json"

    def test_flujo_completo_sin_excepcion(self, config_tres_componentes, tmp_path):
        """
        Flujo completo end-to-end:
        create_package_folders + generate_document + save_package_meta
        ejecutados en secuencia sin lanzar ninguna excepción.
        """
        try:
            pkg_dir = create_package_folders(config_tres_componentes, base_dir=tmp_path)
            doc_path = pkg_dir / "Manual" / f"{config_tres_componentes.package_name}.docx"
            generate_document(config_tres_componentes, doc_path)
            save_package_meta(config_tres_componentes, pkg_dir)
        except Exception as exc:
            pytest.fail(f"El flujo completo falló: {exc}")

        # Verificación final: ambos archivos deben existir
        assert doc_path.exists()
        assert (pkg_dir / "package_meta.json").exists()
