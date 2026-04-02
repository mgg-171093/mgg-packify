"""
Servicio de creación de estructura de carpetas para un package.

Replica exactamente la lógica de v1 (package_generator.py, líneas ~1185-1234):
- Crea {package_name}/Manual/
- Crea {package_name}/Componentes/{FOLDER}/ por cada componente
- Los tipos api_iis, api_docker, apim van a Componentes/API/
- SQL → Componentes/SQL/
- blob → Componentes/BLOB STORAGE/
- liferay → Componentes/LIFERAY/
- liferay_build → NO crea carpeta (solo deploy de build, sin archivos)
- assets → Componentes/ASSETS/
- package_meta.json se guarda en la raíz del package (no en Manual/)
"""

from __future__ import annotations

import json
import logging
from dataclasses import asdict
from pathlib import Path

from mgg_packgen_api.services.component import FOLDER_MAP, ComponentType
from mgg_packgen_api.services.package import PackageConfig

logger = logging.getLogger(__name__)


def create_package_folders(config: PackageConfig, base_dir: Path | None = None) -> Path:
    """
    Crea la estructura de carpetas para el package.

    Estructura generada::

        {base_dir}/{package_name}/
        ├── Manual/
        └── Componentes/
            ├── API/          (si hay api_iis, api_docker o apim)
            ├── SQL/          (si hay sql)
            ├── BLOB STORAGE/ (si hay blob)
            ├── LIFERAY/      (si hay liferay; liferay_build NO crea carpeta)
            └── ASSETS/       (si hay assets)

    Args:
        config: Configuración completa del package.
        base_dir: Directorio base donde crear el package. Si es None,
                  usa config.ruta_packages (debe existir o poder crearse).

    Returns:
        Path al directorio raíz del package creado.
    """
    # Determinar directorio base
    if base_dir is not None:
        root = base_dir / config.package_name
    elif config.ruta_packages:
        root = Path(config.ruta_packages) / config.package_name
    else:
        raise ValueError("Se debe proveer base_dir o config.ruta_packages")

    # Crear Manual/
    manual_dir = root / "Manual"
    manual_dir.mkdir(parents=True, exist_ok=True)
    logger.info("  [DIR] %s", manual_dir)

    # Crear Componentes/{subcarpeta}/ por cada componente (sin duplicados)
    carpetas_creadas: set[str] = set()
    componentes_dir = root / "Componentes"

    for comp in config.componentes:
        tipo = comp.tipo_clave
        # LIFERAY_BUILD no requiere carpeta — es solo un deploy de build, sin archivos
        if tipo == ComponentType.LIFERAY_BUILD:
            continue
        folder_name = FOLDER_MAP.get(tipo, tipo.value.upper())
        if folder_name not in carpetas_creadas:
            subcarpeta = componentes_dir / folder_name
            subcarpeta.mkdir(parents=True, exist_ok=True)
            logger.info("  [DIR] %s", subcarpeta)
            carpetas_creadas.add(folder_name)

        # SQL: crear subcarpeta por base de datos
        if tipo == ComponentType.SQL:
            bd = comp.base_datos or "sin_bd"
            bd_dir = componentes_dir / "SQL" / bd
            if not bd_dir.exists():
                bd_dir.mkdir(parents=True, exist_ok=True)
                logger.info("  [DIR] %s", bd_dir)

    return root


def save_package_meta(config: PackageConfig, package_dir: Path) -> Path:
    """
    Serializa el PackageConfig a JSON y lo guarda en package_meta.json
    en la raíz del package.

    Este archivo permite el modo clone: cargarlo pre-rellena todos los campos
    del formulario principal.

    Args:
        config: Configuración del package a serializar.
        package_dir: Directorio raíz del package.

    Returns:
        Path al archivo package_meta.json creado.
    """
    meta_path = package_dir / "package_meta.json"
    meta_path.parent.mkdir(parents=True, exist_ok=True)

    # Serializar dataclass a dict, convirtiendo Enum a str
    data = _serialize_config(config)

    with meta_path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    logger.info("  [META] %s", meta_path)
    return meta_path


def load_package_meta(meta_path: Path) -> dict:
    """
    Carga el package_meta.json desde disco.

    Args:
        meta_path: Ruta al archivo package_meta.json.

    Returns:
        Dict con los datos del package. Puede usarse para reconstruir
        un PackageConfig en el modo clone.

    Raises:
        FileNotFoundError: Si el archivo no existe.
        json.JSONDecodeError: Si el JSON está corrupto.
    """
    with meta_path.open("r", encoding="utf-8") as f:
        return json.load(f)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS DE SERIALIZACIÓN
# ─────────────────────────────────────────────────────────────────────────────


def _serialize_config(config: PackageConfig) -> dict:
    """
    Convierte PackageConfig a un dict JSON-serializable.

    Los campos Enum se convierten a su valor string.
    Los dataclass anidados se convierten recursivamente.
    """
    raw = asdict(config)
    return _convert_enums(raw)


def _convert_enums(obj: object) -> object:
    """Convierte Enums a strings recursivamente en dicts/listas."""
    if isinstance(obj, dict):
        return {k: _convert_enums(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_convert_enums(item) for item in obj]
    if isinstance(obj, ComponentType):
        return obj.value
    return obj
