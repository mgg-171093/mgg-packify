"""
Pydantic v2 schema para las listas de opciones configurables.
"""

from __future__ import annotations

from pydantic import BaseModel


class ApiIisServiceEntry(BaseModel):
    """Entrada del catálogo de servicios API IIS."""

    nombre: str
    ruta: str


class ApiDockerServiceEntry(BaseModel):
    """Entrada del catálogo de servicios API Docker."""

    nombre: str


class OptionsSchema(BaseModel):
    """Listas de opciones configurables para los dropdowns de la UI."""

    estatus_options: list[str] = ["modificado", "nuevo"]
    tipo_sql_options: list[str] = ["sp", "trigger", "script", "job"]
    tipo_blob_options: list[str] = ["css", "scss", "js"]
    api_iis_services: list[ApiIisServiceEntry] = []
    api_docker_services: list[ApiDockerServiceEntry] = []
    sql_databases: list[str] = []
