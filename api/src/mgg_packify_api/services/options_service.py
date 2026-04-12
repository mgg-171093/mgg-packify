"""
Persistencia de listas de opciones configurables.

Guarda y carga las listas de opciones (estatus, tipo_sql, tipo_blob) en
%APPDATA%\\mgg_packify_api\\options.json (Windows) usando platformdirs.

Si el archivo no existe o está corrupto, devuelve defaults silenciosamente.
"""

from __future__ import annotations

import json
import logging
from pathlib import Path

from platformdirs import user_data_dir

from mgg_packify_api.schemas.options import (
    ApiDockerServiceEntry,
    ApiIisServiceEntry,
    DocTemplatesSchema,
    OptionsSchema,
    ProjectEntry,
)

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# SCHEMA DEL OPTIONS JSON (versión 3)
# ─────────────────────────────────────────────────────────────────────────────
# {
#   "version": 3,
#   "estatus_options": ["modificado", "nuevo"],
#   "tipo_sql_options": ["sp", "trigger", "script", "job"],
#   "tipo_blob_options": ["css", "scss", "js"],
#   "api_iis_services": [{"nombre": "WebRetailAuth", "ruta": "C:\\repos\\..."}],
#   "api_docker_services": [{"nombre": "WorkerService"}],
#   "sql_databases": ["RAWRAPSIIF", "RAWRETAILDB"]
# }

_APP_NAME = "mgg_packify_api"
_OPTIONS_FILE = "options.json"
_SCHEMA_VERSION = 4


def _default_options() -> dict:
    """Devuelve las opciones por defecto."""
    schema = OptionsSchema()
    return {
        "version": _SCHEMA_VERSION,
        "estatus_options": schema.estatus_options,
        "tipo_sql_options": schema.tipo_sql_options,
        "tipo_blob_options": schema.tipo_blob_options,
        "api_iis_services": [],
        "api_docker_services": [],
        "sql_databases": [],
        "doc_templates": {},
        "projects": [],
    }


def _options_path() -> Path:
    """Devuelve la ruta al archivo de opciones del usuario."""
    data_dir = Path(user_data_dir(appname=_APP_NAME, appauthor=False))
    return data_dir / _OPTIONS_FILE


# ─────────────────────────────────────────────────────────────────────────────
# CLASE PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────


class OptionsManager:
    """
    Gestiona la persistencia de listas de opciones configurables.

    Usa platformdirs para determinar la ruta del archivo según el sistema
    operativo. Si el archivo no existe o está corrupto, devuelve defaults
    silenciosamente.
    """

    def __init__(self, options_path: Path | None = None) -> None:
        """
        Inicializa el manager.

        Args:
            options_path: Ruta personalizada al archivo de opciones.
                          Si es None, usa la ruta por defecto de platformdirs.
                          Útil para tests (usar tmp_path).
        """
        self._path = options_path or _options_path()

    # ── Lectura ──────────────────────────────────────────────────────────────

    def load(self) -> OptionsSchema:
        """
        Carga las opciones desde disco.

        Si el archivo no existe, devuelve defaults sin error.
        Si el JSON está corrupto, devuelve defaults silenciosamente.

        Returns:
            OptionsSchema con los valores cargados (o defaults).
        """
        if not self._path.exists():
            return OptionsSchema()

        try:
            with self._path.open("r", encoding="utf-8") as f:
                data = json.load(f)
            _defaults = OptionsSchema()
            # D9: v3→v4 migration — silent fallback for doc_templates
            doc_templates_data = data.get("doc_templates", {})
            return OptionsSchema(
                estatus_options=data.get(
                    "estatus_options", _defaults.estatus_options
                ),
                tipo_sql_options=data.get(
                    "tipo_sql_options", _defaults.tipo_sql_options
                ),
                tipo_blob_options=data.get(
                    "tipo_blob_options", _defaults.tipo_blob_options
                ),
                api_iis_services=[
                    ApiIisServiceEntry(**entry)
                    for entry in data.get("api_iis_services", [])
                ],
                api_docker_services=[
                    ApiDockerServiceEntry(**entry)
                    for entry in data.get("api_docker_services", [])
                ],
                sql_databases=data.get("sql_databases", []),
                doc_templates=DocTemplatesSchema(**doc_templates_data) if doc_templates_data else DocTemplatesSchema(),
                projects=[
                    ProjectEntry(**entry)
                    for entry in data.get("projects", [])
                ],
            )
        except (json.JSONDecodeError, OSError, TypeError, ValueError) as exc:
            logger.warning(
                "Options corrupto o ilegible (%s) — usando defaults.", exc
            )
            return OptionsSchema()

    # ── Escritura ─────────────────────────────────────────────────────────────

    def save(self, options: OptionsSchema) -> None:
        """
        Guarda las opciones en disco.

        Args:
            options: OptionsSchema con los valores a persistir.
        """
        data = {
            "version": _SCHEMA_VERSION,
            "estatus_options": options.estatus_options,
            "tipo_sql_options": options.tipo_sql_options,
            "tipo_blob_options": options.tipo_blob_options,
            "api_iis_services": [
                {"nombre": entry.nombre, "ruta": entry.ruta}
                for entry in options.api_iis_services
            ],
            "api_docker_services": [
                {"nombre": entry.nombre}
                for entry in options.api_docker_services
            ],
            "sql_databases": options.sql_databases,
            "doc_templates": options.doc_templates.model_dump(exclude_none=True),
            "projects": [
                {"id": entry.id, "name": entry.name}
                for entry in options.projects
            ],
        }
        self._write(data)

    # ── Privado ───────────────────────────────────────────────────────────────

    def _write(self, data: dict) -> None:
        """Escribe data en disco, creando el directorio si es necesario."""
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            with self._path.open("w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except OSError as exc:
            logger.error("No se pudo escribir las opciones: %s", exc)
