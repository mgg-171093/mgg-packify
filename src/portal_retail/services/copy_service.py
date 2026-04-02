"""
Servicio de copia de archivos a las subcarpetas de un package.

Permite copiar archivos de componentes desde un directorio fuente
a las carpetas correspondientes del package generado.
"""

from __future__ import annotations

import logging
import shutil
from dataclasses import dataclass, field
from pathlib import Path

from portal_retail.core.component import FOLDER_MAP, ComponentType
from portal_retail.core.package import PackageConfig

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# RESULTADO DE LA OPERACIÓN DE COPIA
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class CopyResult:
    """Resultado de una operación de copia de archivos."""

    copied: list[Path] = field(default_factory=list)
    """Archivos copiados exitosamente."""
    warnings: list[str] = field(default_factory=list)
    """Advertencias por archivos no encontrados o con error."""
    errors: list[str] = field(default_factory=list)
    """Errores fatales durante la copia."""

    @property
    def success(self) -> bool:
        """True si no hubo errores fatales."""
        return len(self.errors) == 0

    @property
    def total_copied(self) -> int:
        return len(self.copied)

    @property
    def total_warnings(self) -> int:
        return len(self.warnings)


# ─────────────────────────────────────────────────────────────────────────────
# FUNCIONES PRINCIPALES
# ─────────────────────────────────────────────────────────────────────────────

def list_copyable_files(source_dir: Path) -> list[Path]:
    """
    Lista los archivos disponibles en un directorio fuente.

    Solo lista archivos (no directorios). No es recursivo — lista solo
    el nivel superior del directorio. Útil para mostrar checkboxes en la TUI.

    Args:
        source_dir: Directorio donde buscar archivos.

    Returns:
        Lista de Paths a los archivos encontrados, ordenada por nombre.

    Raises:
        FileNotFoundError: Si source_dir no existe.
    """
    if not source_dir.exists():
        raise FileNotFoundError(f"El directorio fuente no existe: {source_dir}")

    return sorted(
        [p for p in source_dir.iterdir() if p.is_file()],
        key=lambda p: p.name.lower(),
    )


def copy_files_to_package(
    files: list[Path],
    package_root: Path,
    config: PackageConfig,
) -> dict[Path, bool]:
    """
    Copia una lista de archivos al directorio raíz del package.

    Determina la subcarpeta destino según el tipo de componente del archivo.
    Si un archivo no existe, registra una advertencia en el resultado y continúa.

    Args:
        files: Lista de archivos a copiar.
        package_root: Directorio raíz del package (creado por folder_service).
        config: PackageConfig para determinar la carpeta destino de cada archivo.

    Returns:
        Dict mapeando cada Path a bool (True = copiado, False = falló).
    """
    result: dict[Path, bool] = {}

    for src in files:
        if not src.exists():
            logger.warning("Archivo no encontrado, omitiendo: %s", src)
            result[src] = False
            continue

        # Determinar carpeta destino
        dest_dir = _resolve_dest_dir(src, package_root, config)
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / src.name

        try:
            shutil.copy2(src, dest)
            logger.info("  [COPY] %s → %s", src.name, dest_dir)
            result[src] = True
        except OSError as exc:
            logger.error("Error copiando %s: %s", src, exc)
            result[src] = False

    return result


def copy_files(
    selections: dict[ComponentType, list[Path]],
    package_dir: Path,
) -> CopyResult:
    """
    Copia archivos organizados por ComponentType al package.

    Interfaz de alto nivel usada por la TUI (copy_screen). Cada tipo
    mapea a la subcarpeta correspondiente en Componentes/.

    Args:
        selections: Dict de ComponentType → lista de Paths a copiar.
        package_dir: Directorio raíz del package.

    Returns:
        CopyResult con detalles de éxitos y advertencias.
    """
    result = CopyResult()
    componentes_dir = package_dir / "Componentes"

    for comp_type, files in selections.items():
        folder_name = FOLDER_MAP.get(comp_type, comp_type.value.upper())
        dest_dir = componentes_dir / folder_name
        dest_dir.mkdir(parents=True, exist_ok=True)

        for src in files:
            if not src.exists():
                msg = f"Archivo no encontrado: {src}"
                logger.warning(msg)
                result.warnings.append(msg)
                continue

            dest = dest_dir / src.name
            try:
                shutil.copy2(src, dest)
                logger.info("  [COPY] %s → %s", src.name, dest_dir)
                result.copied.append(dest)
            except OSError as exc:
                msg = f"Error copiando {src.name}: {exc}"
                logger.error(msg)
                result.errors.append(msg)

    return result


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _resolve_dest_dir(src: Path, package_root: Path, config: PackageConfig) -> Path:
    """
    Determina la carpeta destino para un archivo dentro del package.

    Intenta inferir el tipo de componente desde la extensión del archivo
    o el directorio padre. Si no puede determinarlo, usa la carpeta
    del primer componente del config, o Componentes/ como fallback.
    """
    componentes_dir = package_root / "Componentes"

    # Inferencia por extensión
    ext = src.suffix.lower()
    if ext == ".zip":
        return componentes_dir / "API"
    if ext in (".sql", ".bak"):
        return componentes_dir / "SQL"
    if ext in (".js", ".css", ".png", ".jpg", ".svg", ".gif", ".webp"):
        return componentes_dir / "BLOB STORAGE"

    # Fallback: primer componente del config
    if config.componentes:
        first_type = config.componentes[0].tipo_clave
        folder = FOLDER_MAP.get(first_type, "Componentes")
        return componentes_dir / folder

    return componentes_dir
