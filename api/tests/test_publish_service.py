"""
Tests unitarios para mgg_packgen_api.services.publish_service

Cubre:
  - detect_framework: detección de .NET Framework (v) y .NET Core
  - find_msbuild: not found y found via vswhere
  - publish_api_iis: success, failure (build error), no msbuild
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from mgg_packgen_api.services import publish_service
from mgg_packgen_api.services.publish_service import (
    PublishResult,
    detect_framework,
    find_msbuild,
    publish_api_iis,
)


# ─────────────────────────────────────────────────────────────────────────────
# detect_framework
# ─────────────────────────────────────────────────────────────────────────────


def test_detect_framework_dotnet_fx(tmp_path: Path) -> None:
    """Un .csproj con TargetFrameworkVersion debe devolver el valor (ej: 'v4.5')."""
    csproj_content = """<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0" DefaultTargets="Build">
  <PropertyGroup>
    <TargetFrameworkVersion>v4.5</TargetFrameworkVersion>
    <Configuration>Release</Configuration>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "MyApi.csproj").write_text(csproj_content, encoding="utf-8")

    result = detect_framework(str(tmp_path))

    assert result == "v4.5"


def test_detect_framework_dotnet_core(tmp_path: Path) -> None:
    """Un .csproj con TargetFramework debe devolver el valor (ej: 'net6.0')."""
    csproj_content = """<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "MyApi.csproj").write_text(csproj_content, encoding="utf-8")

    result = detect_framework(str(tmp_path))

    assert result == "net6.0"


def test_detect_framework_no_csproj(tmp_path: Path) -> None:
    """Sin .csproj en el directorio debe devolver cadena vacía."""
    result = detect_framework(str(tmp_path))

    assert result == ""


# ─────────────────────────────────────────────────────────────────────────────
# find_msbuild
# ─────────────────────────────────────────────────────────────────────────────


def test_find_msbuild_not_found_vswhere_missing() -> None:
    """Si vswhere.exe no está en la ruta esperada, find_msbuild devuelve None."""
    # Monkeypatch Path.exists para que _VSWHERE_PATH no exista
    with patch.object(Path, "exists", return_value=False):
        result = find_msbuild()

    assert result is None


def test_find_msbuild_not_found_subprocess_raises() -> None:
    """Si subprocess.run lanza FileNotFoundError, find_msbuild devuelve None."""
    # Hacer que vswhere.exe "exista" pero subprocess.run falle
    with patch.object(Path, "exists", return_value=True):
        with patch("subprocess.run", side_effect=FileNotFoundError("vswhere not found")):
            result = find_msbuild()

    assert result is None


def test_find_msbuild_found() -> None:
    """Si vswhere devuelve una ruta válida, find_msbuild la retorna limpia."""
    mock_proc = MagicMock()
    mock_proc.stdout = r"C:\msbuild\MSBuild.exe" + "\n"

    with patch.object(Path, "exists", return_value=True):
        with patch("subprocess.run", return_value=mock_proc):
            result = find_msbuild()

    assert result == r"C:\msbuild\MSBuild.exe"


# ─────────────────────────────────────────────────────────────────────────────
# publish_api_iis
# ─────────────────────────────────────────────────────────────────────────────


def test_publish_api_iis_no_csproj(tmp_path: Path) -> None:
    """Si no hay .csproj en el directorio, PublishResult.ok debe ser False."""
    dest_dir = tmp_path / "out"

    result = publish_api_iis("SvcA", str(tmp_path), dest_dir)

    assert result.ok is False
    assert result.nombre == "SvcA"
    assert "csproj" in result.error.lower()


def test_publish_api_iis_no_msbuild(tmp_path: Path) -> None:
    """Si find_msbuild devuelve None (proyecto .NET FX), PublishResult.ok=False."""
    # Crear .csproj con .NET Framework
    csproj_content = """<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0">
  <PropertyGroup>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "SvcA.csproj").write_text(csproj_content, encoding="utf-8")
    dest_dir = tmp_path / "out"

    with patch.object(publish_service, "find_msbuild", return_value=None):
        result = publish_api_iis("SvcA", str(tmp_path), dest_dir)

    assert result.ok is False
    assert result.nombre == "SvcA"
    assert "MSBuild" in result.error or "msbuild" in result.error.lower()


def test_publish_api_iis_success(tmp_path: Path) -> None:
    """Publicación exitosa: subprocess retorna 0, PublishResult.ok=True con zip_path."""
    # .csproj con .NET Framework (usará MSBuild)
    csproj_content = """<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0">
  <PropertyGroup>
    <TargetFrameworkVersion>v4.5</TargetFrameworkVersion>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "SvcA.csproj").write_text(csproj_content, encoding="utf-8")
    dest_dir = tmp_path / "out"

    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = ""
    mock_proc.stderr = ""

    with patch.object(publish_service, "find_msbuild", return_value=r"C:\msbuild\MSBuild.exe"):
        with patch("subprocess.run", return_value=mock_proc):
            result = publish_api_iis("SvcA", str(tmp_path), dest_dir)

    assert result.ok is True
    assert result.nombre == "SvcA"
    assert result.zip_path is not None
    assert result.zip_path.endswith("SvcA.zip")


def test_publish_api_iis_failure_msbuild(tmp_path: Path) -> None:
    """Cuando subprocess retorna returncode != 0, PublishResult.ok=False con error."""
    csproj_content = """<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0">
  <PropertyGroup>
    <TargetFrameworkVersion>v4.5</TargetFrameworkVersion>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "SvcA.csproj").write_text(csproj_content, encoding="utf-8")
    dest_dir = tmp_path / "out"

    mock_proc = MagicMock()
    mock_proc.returncode = 1
    mock_proc.stdout = ""
    mock_proc.stderr = "Build FAILED.\nError MSB1234: compilation error"

    with patch.object(publish_service, "find_msbuild", return_value=r"C:\msbuild\MSBuild.exe"):
        with patch("subprocess.run", return_value=mock_proc):
            result = publish_api_iis("SvcA", str(tmp_path), dest_dir)

    assert result.ok is False
    assert result.nombre == "SvcA"
    assert result.error  # debe tener algún mensaje de error
    assert result.zip_path is None


def test_publish_api_iis_success_dotnet_core(tmp_path: Path) -> None:
    """Publicación exitosa con .NET Core (dotnet publish): ok=True."""
    csproj_content = """<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
  </PropertyGroup>
</Project>
"""
    (tmp_path / "SvcA.csproj").write_text(csproj_content, encoding="utf-8")
    dest_dir = tmp_path / "out"

    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "Build succeeded."
    mock_proc.stderr = ""

    # dotnet core no necesita find_msbuild — va directo a dotnet publish
    with patch("subprocess.run", return_value=mock_proc):
        result = publish_api_iis("SvcA", str(tmp_path), dest_dir)

    assert result.ok is True
    assert result.zip_path is not None
