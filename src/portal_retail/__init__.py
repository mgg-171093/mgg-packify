"""Portal Retail — Generador de Packages de Instalación (TUI v2)."""

__version__ = "2.0.0"
__author__ = "Manuel García González"
__description__ = "Generador de packages de instalación para Portal Retail Skandia México"

from portal_retail.core.component import ComponentConfig, ComponentType
from portal_retail.core.package import PackageConfig, ServerConfig

__all__ = [
    "__version__",
    "__author__",
    "__description__",
    "ComponentConfig",
    "ComponentType",
    "PackageConfig",
    "ServerConfig",
]
