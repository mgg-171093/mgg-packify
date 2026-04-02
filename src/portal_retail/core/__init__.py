"""Core domain: tipos de componente, configuración de packages y naming."""

from portal_retail.core.component import (
    COMPONENT_LABELS,
    COMPONENT_ORDER,
    ETIQUETA_GRUPO,
    FOLDER_MAP,
    ComponentConfig,
    ComponentType,
)
from portal_retail.core.package import PackageConfig, ServerConfig

__all__ = [
    "ComponentConfig",
    "ComponentType",
    "COMPONENT_ORDER",
    "COMPONENT_LABELS",
    "ETIQUETA_GRUPO",
    "FOLDER_MAP",
    "PackageConfig",
    "ServerConfig",
]
