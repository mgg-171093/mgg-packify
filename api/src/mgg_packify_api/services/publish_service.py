"""
Servicio de publicación de APIs IIS.

Detecta el framework de un proyecto .NET, ejecuta el proceso de publicación
(MSBuild para .NET Framework, dotnet publish para .NET Core/5+), y empaqueta
el resultado en un archivo .zip.

Funciones públicas:
  - detect_framework(ruta) → str
  - find_msbuild() → str | None
  - publish_api_iis(nombre, ruta, dest_dir) → PublishResult
"""

from __future__ import annotations

import logging
import subprocess
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

logger = logging.getLogger(__name__)

# Ruta estándar al instalador de Visual Studio en Windows
_VSWHERE_PATH = (
    r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
)


# ─────────────────────────────────────────────────────────────────────────────
# DATACLASS DE RESULTADO
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class PublishResult:
    """Resultado de una operación de publicación de API IIS."""

    nombre: str
    ok: bool
    zip_path: str | None = None
    error: str = ""


# ─────────────────────────────────────────────────────────────────────────────
# DETECCIÓN DE FRAMEWORK
# ─────────────────────────────────────────────────────────────────────────────


def detect_framework(ruta: str) -> str:
    """
    Detecta el framework objetivo del proyecto .NET en *ruta*.

    Parsea el primer archivo *.csproj encontrado en el directorio.
    Busca:
      - <TargetFramework>net6.0</TargetFramework>  → devuelve "net6.0"
      - <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion> → devuelve "v4.7.2"

    Args:
        ruta: Directorio que contiene el archivo .csproj.

    Returns:
        Cadena con el framework detectado, o "" si no se encuentra.
    """
    csproj_files = list(Path(ruta).glob("*.csproj"))
    if not csproj_files:
        logger.warning("No se encontró .csproj en: %s", ruta)
        return ""

    csproj = csproj_files[0]
    try:
        tree = ET.parse(str(csproj))
        root = tree.getroot()

        # Buscar sin namespace y con namespace wildcard
        for elem in root.iter():
            local = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if local == "TargetFramework" and elem.text:
                return elem.text.strip()
            if local == "TargetFrameworkVersion" and elem.text:
                return elem.text.strip()

    except ET.ParseError as exc:
        logger.warning("Error parseando %s: %s", csproj, exc)

    return ""


# ─────────────────────────────────────────────────────────────────────────────
# LOCALIZACIÓN DE MSBUILD
# ─────────────────────────────────────────────────────────────────────────────


def find_msbuild() -> str | None:
    """
    Localiza el ejecutable MSBuild.exe usando vswhere.exe.

    Command:
        vswhere -latest -requires Microsoft.Component.MSBuild
                -find "MSBuild\\**\\Bin\\MSBuild.exe"

    Returns:
        Ruta completa al MSBuild.exe, o None si no se encuentra.
    """
    if not Path(_VSWHERE_PATH).exists():
        logger.warning("vswhere.exe no encontrado en: %s", _VSWHERE_PATH)
        return None

    try:
        proc = subprocess.run(
            [
                _VSWHERE_PATH,
                "-latest",
                "-requires", "Microsoft.Component.MSBuild",
                "-find", r"MSBuild\**\Bin\MSBuild.exe",
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )
        lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
        if lines:
            return lines[-1]
    except (subprocess.TimeoutExpired, OSError, FileNotFoundError) as exc:
        logger.warning("Error al ejecutar vswhere: %s", exc)

    return None


# ─────────────────────────────────────────────────────────────────────────────
# PUBLICACIÓN DE API IIS
# ─────────────────────────────────────────────────────────────────────────────


def publish_api_iis(nombre: str, ruta: str, dest_dir: Path) -> PublishResult:
    """
    Publica un proyecto API IIS y empaqueta el resultado en un .zip.

    Pasos:
      1. detect_framework(ruta) → elige MSBuild o dotnet publish
      2. Crea un directorio temporal para la salida de publicación
      3. Localiza el .csproj
      4. Ejecuta la publicación (MSBuild o dotnet)
      5. Comprime el resultado en dest_dir/{nombre}.zip
      6. Limpia el directorio temporal (try/finally)

    Args:
        nombre: Nombre del servicio (usado como nombre del .zip).
        ruta:   Ruta al directorio que contiene el .csproj.
        dest_dir: Directorio de destino para el .zip resultante.

    Returns:
        PublishResult con ok=True y zip_path si se completó correctamente,
        o ok=False y error con el motivo del fallo.
    """
    tmp_dir_obj = tempfile.TemporaryDirectory()
    try:
        tmp_publish = tmp_dir_obj.name

        # 1. Detectar framework
        framework = detect_framework(ruta)

        # 3. Localizar .csproj
        csproj_files = list(Path(ruta).glob("*.csproj"))
        if not csproj_files:
            return PublishResult(
                nombre=nombre,
                ok=False,
                error=f"No se encontró archivo .csproj en: {ruta}",
            )
        csproj = csproj_files[0]

        # 4. Armar comando de publicación
        if framework.startswith("v"):
            # .NET Framework → MSBuild /t:WebPublish
            msbuild_path = find_msbuild()
            if msbuild_path is None:
                return PublishResult(
                    nombre=nombre,
                    ok=False,
                    error=(
                        "MSBuild no encontrado. Asegurate de tener Visual Studio "
                        "instalado con el componente MSBuild."
                    ),
                )
            cmd = [
                msbuild_path,
                str(csproj),
                "/t:WebPublish",
                "/p:Configuration=Release",
                "/p:WebPublishMethod=FileSystem",
                f"/p:PublishUrl={tmp_publish}\\",
                "/p:DeleteExistingFiles=true",
                "/p:DeployOnBuild=true",
                "/p:LaunchSiteAfterPublish=false",
            ]
        else:
            # .NET Core / .NET 5+ → dotnet publish
            cmd = [
                "dotnet",
                "publish",
                str(csproj),
                "-c", "Release",
                "-o", tmp_publish,
            ]

        # 6. Ejecutar
        logger.info("Publicando %s: %s", nombre, " ".join(cmd))
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
        )

        # 7. Verificar resultado
        if proc.returncode != 0:
            error_tail = proc.stderr[-500:] if proc.stderr else proc.stdout[-500:]
            return PublishResult(
                nombre=nombre,
                ok=False,
                error=error_tail,
            )

        # 8. Comprimir
        dest_dir.mkdir(parents=True, exist_ok=True)
        zip_path = dest_dir / f"{nombre}.zip"
        with zipfile.ZipFile(str(zip_path), "w", zipfile.ZIP_DEFLATED) as zf:
            pub_path = Path(tmp_publish)
            for file_path in pub_path.rglob("*"):
                if file_path.is_file():
                    arcname = file_path.relative_to(pub_path)
                    zf.write(str(file_path), str(arcname))

        logger.info("Publicación de %s completada: %s", nombre, zip_path)
        return PublishResult(nombre=nombre, ok=True, zip_path=str(zip_path))

    except subprocess.TimeoutExpired:
        return PublishResult(
            nombre=nombre,
            ok=False,
            error="Timeout: la publicación tardó más de 5 minutos.",
        )
    except Exception as exc:  # noqa: BLE001
        logger.exception("Error inesperado publicando %s", nombre)
        return PublishResult(nombre=nombre, ok=False, error=str(exc))
    finally:
        try:
            tmp_dir_obj.cleanup()
        except Exception:  # noqa: BLE001
            pass
