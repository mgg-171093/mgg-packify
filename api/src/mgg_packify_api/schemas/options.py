"""
Pydantic v2 schema para las listas de opciones configurables.
"""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class ProjectEntry(BaseModel):
    """Entrada del catálogo de proyectos."""

    id: str
    name: str


class ApiIisServiceEntry(BaseModel):
    """Entrada del catálogo de servicios API IIS."""

    nombre: str
    ruta: str


class ApiDockerServiceEntry(BaseModel):
    """Entrada del catálogo de servicios API Docker."""

    nombre: str


# ---------------------------------------------------------------------------
# Doc Templates — sub-models (D2: 9 typed sub-models)
# ---------------------------------------------------------------------------


class DocTemplatesDocSection(BaseModel):
    title: Optional[str] = None
    section1_title: Optional[str] = None
    note_text: Optional[str] = None
    section2_title: Optional[str] = None


class DocTemplatesSqlSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_execute: Optional[str] = None


class DocTemplatesApiIisSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_update_service: Optional[str] = None
    step_update_configs: Optional[str] = None
    step_deploy_jenkins: Optional[str] = None
    step_update_apim: Optional[str] = None


class DocTemplatesApiDockerSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_update_service: Optional[str] = None
    step_deploy_jenkins: Optional[str] = None
    step_update_apim: Optional[str] = None
    step_update_env: Optional[str] = None


class DocTemplatesBlobSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_validate_folder: Optional[str] = None
    step_upload_files: Optional[str] = None
    step_generate_sas: Optional[str] = None


class DocTemplatesLiferayBuildSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None


class DocTemplatesLiferaySection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_create_remote_app: Optional[str] = None
    step_go_site: Optional[str] = None
    step_create_page: Optional[str] = None
    step_edit_page: Optional[str] = None
    step_drag_widget: Optional[str] = None
    step_publish: Optional[str] = None


class DocTemplatesAssetsSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_navigate: Optional[str] = None
    step_upload: Optional[str] = None


class DocTemplatesApimSection(BaseModel):
    h2_title: Optional[str] = None
    h3_subtitle: Optional[str] = None
    step_update_service: Optional[str] = None


class DocTemplatesSchema(BaseModel):
    doc: DocTemplatesDocSection = Field(default_factory=DocTemplatesDocSection)
    sql: DocTemplatesSqlSection = Field(default_factory=DocTemplatesSqlSection)
    api_iis: DocTemplatesApiIisSection = Field(default_factory=DocTemplatesApiIisSection)
    api_docker: DocTemplatesApiDockerSection = Field(default_factory=DocTemplatesApiDockerSection)
    blob: DocTemplatesBlobSection = Field(default_factory=DocTemplatesBlobSection)
    liferay_build: DocTemplatesLiferayBuildSection = Field(default_factory=DocTemplatesLiferayBuildSection)
    liferay: DocTemplatesLiferaySection = Field(default_factory=DocTemplatesLiferaySection)
    assets: DocTemplatesAssetsSection = Field(default_factory=DocTemplatesAssetsSection)
    apim: DocTemplatesApimSection = Field(default_factory=DocTemplatesApimSection)

    def to_overrides_dict(self) -> dict[str, dict[str, str]]:
        """Convert to nested dict for _resolve_text(), omitting None values."""
        result = {}
        for section_name, section_model in self.model_dump(exclude_none=True).items():
            if section_model:
                result[section_name] = section_model
        return result


class OptionsSchema(BaseModel):
    """Listas de opciones configurables para los dropdowns de la UI."""

    estatus_options: list[str] = ["modificado", "nuevo"]
    tipo_sql_options: list[str] = ["sp", "trigger", "script", "job"]
    tipo_blob_options: list[str] = ["css", "scss", "js"]
    api_iis_services: list[ApiIisServiceEntry] = []
    api_docker_services: list[ApiDockerServiceEntry] = []
    sql_databases: list[str] = []
    doc_templates: DocTemplatesSchema = Field(default_factory=DocTemplatesSchema)
    projects: list[ProjectEntry] = []
