"""
Pydantic v2 models para request/response de packages.
"""

from __future__ import annotations

from pydantic import BaseModel


class ConfigItemIn(BaseModel):
    clave: str
    valor: str
    imagen_path: str | None = None


class ArchivoItemIn(BaseModel):
    nombre: str
    carpeta: str = ""


class InstanceIn(BaseModel):
    """Una instancia de un componente — campos planos, todos opcionales."""
    # liferay_build
    build_id: str = ""
    # sql
    base_datos: str = ""
    scripts: list[str] = []
    # api_iis / api_docker / apim
    nombre_servicio: str = ""
    configs: list[ConfigItemIn] = []
    # blob / assets
    archivos: list[ArchivoItemIn] = []
    # liferay remote app
    nombre: str = ""
    es_nueva: bool = False
    crear_pagina: bool = False
    pagina: str = ""
    widgets: list[str] = []
    # common — all component types
    estatus: str = "modificado"
    tipo: str = ""
    # api_iis — publish flag
    publicar: bool = False
    # api_docker / api_iis — optional steps in docx
    jenkins: bool = True
    actualizar_apim: bool = True
    # sql — per-script copy flags (parallel to scripts[])
    scripts_copiar: list[bool] = []


class ComponentIn(BaseModel):
    """Componente con sus instancias — formato que emite Flutter."""
    tipo: str                           # "sql", "api_iis", etc.
    instancias: list[InstanceIn] = []


class GenerateRequest(BaseModel):
    ticket: str
    hu_nombre: str = ""
    ambiente: str                       # "qa" | "prod"  (Flutter manda lowercase)
    iteracion: str
    ruta_packages: str
    componentes: list[ComponentIn]
    project_name: str = ""              # nombre del proyecto (backward-compatible)


class StepResult(BaseModel):
    """Resultado de un paso de ejecución (ej: publicación de un servicio)."""

    label: str
    ok: bool
    error: str = ""


class GenerateResponse(BaseModel):
    ok: bool
    package_name: str = ""
    package_dir: str = ""
    doc_path: str = ""
    folders_created: list[str] = []
    error: str = ""
    steps: list[StepResult] = []
    publish_outputs: list[str] = []
    copy_errors: list[str] = []


class CloneRequest(BaseModel):
    source_path: str
    new_iteracion: str


class CloneResponse(BaseModel):
    ok: bool
    prefill: dict = {}
    error: str = ""


class PackageListItem(BaseModel):
    name: str
    path: str
    has_meta: bool
    created_at: str                     # ISO 8601


class PackageListResponse(BaseModel):
    packages: list[PackageListItem]
