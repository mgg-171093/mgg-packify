"""
Configuración de un package de instalación.

PackageConfig agrupa todos los datos necesarios para generar la estructura
de carpetas y el manual .docx. ServerConfig contiene los servidores por
ambiente (QA / PROD).
"""

from __future__ import annotations

from dataclasses import dataclass, field

from mgg_packify_api.services.component import ComponentConfig

# ─────────────────────────────────────────────────────────────────────────────
# SERVIDORES POR AMBIENTE
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class ServerConfig:
    """
    IPs / nombres de servidor para un ambiente (QA o PROD).

    Todos los campos son opcionales — si están vacíos, el doc generator
    usa un texto genérico como fallback ('Servidor BD QA', etc.).
    """

    api: str = ""
    """Servidor de servicios / APIs (IIS, Docker, APIM)."""
    bd: str = ""
    """Servidor de base de datos (SQL)."""
    blob: str = ""
    """Cuenta / URL de Azure Blob Storage."""
    liferay: str = ""
    """Servidor de Liferay (Remote App, Assets, Build)."""


# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DEL PACKAGE
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class PackageConfig:
    """
    Datos completos para generar un package de instalación.

    Contiene los metadatos del ticket, los componentes seleccionados y la
    configuración de servidores. La property `package_name` calcula el nombre
    canónico del package según la convención de v1.
    """

    ticket: str
    """Número de ticket (ej: MX01-274906)."""
    hu_nombre: str
    """Nombre de la HU / Fix / Spike para el título del manual."""
    ambiente: str
    """Ambiente destino: 'QA' o 'PROD'."""
    iteracion: str
    """Número de iteración del package (ej: '01', '02')."""
    ruta_packages: str = ""
    """Ruta base donde se crea la estructura de carpetas del package."""
    componentes: list[ComponentConfig] = field(default_factory=list)
    """Lista de componentes incluidos en el package."""
    servidores: ServerConfig = field(default_factory=ServerConfig)
    """Servidores del ambiente target."""
    project_name: str = ""
    """Nombre del proyecto (ej: 'MiProyecto'). Vacío usa 'GenericProject' como fallback."""

    @property
    def package_name(self) -> str:
        """
        Nombre canónico del package.

        Formato: ``{ticket}-{project_name}_{ambiente}-{iteracion.zfill(2)}``

        Si ``project_name`` está vacío, usa ``"GenericProject"`` como fallback.

        Nota: el campo hu_nombre NO forma parte del nombre de la carpeta/archivo
        (se usa solo en el título del documento .docx). Esto replica exactamente
        el comportamiento de v1.
        """
        label = self.project_name or "GenericProject"
        iter_str = self.iteracion.zfill(2)
        return f"{self.ticket}-{label}_{self.ambiente}-{iter_str}"
