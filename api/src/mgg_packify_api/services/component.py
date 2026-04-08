"""
Tipos de componente del Portal Retail.

Define el enum ComponentType con los 8 valores canónicos, el orden
de renderizado y el dataclass ComponentConfig con todos los campos
opcionales por tipo de componente.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum

# ─────────────────────────────────────────────────────────────────────────────
# TIPOS DE COMPONENTE
# ─────────────────────────────────────────────────────────────────────────────


class ComponentType(StrEnum):
    """Tipos de componente disponibles en el Portal Retail."""

    LIFERAY_BUILD = "liferay_build"
    SQL = "sql"
    API_IIS = "api_iis"
    API_DOCKER = "api_docker"
    BLOB = "blob"
    LIFERAY = "liferay"
    ASSETS = "assets"
    APIM = "apim"


# Orden canónico de renderizado en el documento (idéntico a v1)
COMPONENT_ORDER: list[ComponentType] = [
    ComponentType.LIFERAY_BUILD,
    ComponentType.SQL,
    ComponentType.API_IIS,
    ComponentType.API_DOCKER,
    ComponentType.BLOB,
    ComponentType.LIFERAY,
    ComponentType.ASSETS,
    ComponentType.APIM,
]

# Etiqueta de grupo para las filas separadoras de la tabla de componentes
ETIQUETA_GRUPO: dict[ComponentType, str] = {
    ComponentType.LIFERAY_BUILD: "LIFERAY",
    ComponentType.SQL: "SQL",
    ComponentType.API_IIS: "API",
    ComponentType.API_DOCKER: "API",
    ComponentType.BLOB: "Blob Storage",
    ComponentType.LIFERAY: "LIFERAY",
    ComponentType.ASSETS: "Assets",
    ComponentType.APIM: "API Management",
}

# Nombre de carpeta de componente en la estructura de paquete (mapa de v1)
FOLDER_MAP: dict[ComponentType, str] = {
    ComponentType.LIFERAY_BUILD: "LIFERAY",
    ComponentType.SQL: "SQL",
    ComponentType.API_IIS: "API",
    ComponentType.API_DOCKER: "API",
    ComponentType.BLOB: "BLOB STORAGE",
    ComponentType.LIFERAY: "LIFERAY",
    ComponentType.ASSETS: "ASSETS",
    ComponentType.APIM: "API",
}

# Valor de columna TIPO en la tabla del documento (legible para el usuario)
TIPO_DISPLAY: dict[ComponentType, str] = {
    ComponentType.LIFERAY_BUILD: "Liferay",
    ComponentType.SQL: "SQL",
    ComponentType.API_IIS: "API",
    ComponentType.API_DOCKER: "API",
    ComponentType.BLOB: "Blob Storage",
    ComponentType.LIFERAY: "Liferay",
    ComponentType.ASSETS: "Assets",
    ComponentType.APIM: "API Management",
}

# Labels de display para el selector de componentes en la UI
COMPONENT_LABELS: dict[ComponentType, str] = {
    ComponentType.LIFERAY_BUILD: "Liferay build",
    ComponentType.SQL: "SQL",
    ComponentType.API_IIS: "API IIS",
    ComponentType.API_DOCKER: "API Docker",
    ComponentType.BLOB: "Blob Storage (JS/CSS)",
    ComponentType.LIFERAY: "Liferay (Remote App / Página)",
    ComponentType.ASSETS: "Assets (imágenes Liferay)",
    ComponentType.APIM: "Azure API Management",
}


# ─────────────────────────────────────────────────────────────────────────────
# DATACLASS DE CONFIGURACIÓN DE COMPONENTE
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class ComponentConfig:
    """
    Configuración de un componente dentro de un package.

    Los campos tipo_clave, nombre_display, tipo_display, contenedor y estatus
    son comunes a todos los tipos. Los demás campos son opcionales y se usan
    según el tipo de componente.
    """

    # Campos obligatorios
    tipo_clave: ComponentType
    nombre_display: str
    tipo_display: str
    contenedor: str
    estatus: str = "modificado"

    # ── SQL ──────────────────────────────────────────────────────────────────
    scripts: list[str] = field(default_factory=list)
    """Lista de nombres de scripts SQL a ejecutar."""
    base_datos: str = ""
    """Nombre de la base de datos destino (ej: RAWRAPSIIF)."""

    # ── API IIS / API Docker / APIM ──────────────────────────────────────────
    nombre_servicio: str = ""
    """Nombre del servicio/API (sin .zip para IIS, sin extensión para Docker/APIM)."""
    configs: list[dict[str, str]] = field(default_factory=list)
    """Lista de configuraciones clave-valor (appsettings, env vars)."""

    # ── Blob Storage / Assets ────────────────────────────────────────────────
    archivos: list[dict[str, str]] = field(default_factory=list)
    """Lista de archivos con 'nombre', 'carpeta', 'estatus'."""

    # ── Liferay Build ────────────────────────────────────────────────────────
    build_id: str = ""
    """Número de Build ID para el deploy de Liferay (ej: 7957)."""

    # ── Liferay Remote App ───────────────────────────────────────────────────
    nombre: str = ""
    """Nombre de la Remote App de Liferay."""
    tipo: str = ""
    """Subtipo: 'remote_app' para Liferay."""
    crear_pagina: bool = False
    """Si se debe crear/actualizar una página en Liferay."""
    pagina: str = ""
    """Nombre de la página de Liferay a crear/actualizar."""
    widgets: list[str] = field(default_factory=list)
    """Widgets a agregar en la página de Liferay."""

    # ── API IIS — publish ────────────────────────────────────────────────────
    publicar: bool = False
    """Si se debe publicar el servicio IIS vía MSBuild/dotnet publish."""
    ruta: str = ""
    """Ruta al proyecto .csproj en el repositorio (sólo para api_iis)."""

    # ── API Docker / API IIS — optional docx steps ───────────────────────────
    jenkins: bool = True
    """Si se debe incluir el paso 'Hacer el despliegue CI/CD en Jenkins' en el docx."""
    actualizar_apim: bool = True
    """Si se debe incluir el paso 'Actualizar el schema del Api Management de AZURE' en el docx."""
