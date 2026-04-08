"""
Rutas de packages:
  POST /packages/generate
  POST /packages/clone
  GET  /packages/list
"""

from __future__ import annotations

import os
import shutil
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, HTTPException

from mgg_packify_api.schemas.package import (
    CloneRequest,
    CloneResponse,
    ComponentIn,
    GenerateRequest,
    GenerateResponse,
    InstanceIn,
    PackageListItem,
    PackageListResponse,
    StepResult,
)
from mgg_packify_api.services import publish_service
from mgg_packify_api.services.component import ComponentConfig, ComponentType
from mgg_packify_api.services.doc_generator import generate_document
from mgg_packify_api.services.folder_service import (
    create_package_folders,
    load_package_meta,
    save_package_meta,
)
from mgg_packify_api.services.options_service import OptionsManager
from mgg_packify_api.services.package import PackageConfig

router = APIRouter()

# Orden canónico de componentes
_CANONICAL_ORDER = [
    "liferay_build",
    "sql",
    "api_iis",
    "api_docker",
    "blob",
    "liferay",
    "assets",
    "apim",
]

# Singleton del options manager — monkeypatchable en tests
_options_manager = OptionsManager()


def _derive_component_config(comp: ComponentIn, inst: InstanceIn) -> list[ComponentConfig]:
    """
    Construye una lista de ComponentConfig a partir de un ComponentIn y una InstanceIn.

    Flutter envía {tipo, instancias:[...]} — cada instancia se expande en N filas:
    - sql: 1 fila por script (CONTENEDOR=nombre_bd, estatus/tipo de inst)
    - blob: 1 fila por archivo (CONTENEDOR='Azure Blob Storage', estatus/tipo de inst)
    - resto: 1 fila por instancia
    """
    tipo = ComponentType(comp.tipo)
    # REQ-IMG-03: incluir imagen_path en cada config dict si está presente
    configs_list = [
        {"clave": cfg.clave, "valor": cfg.valor, **({"imagen_path": cfg.imagen_path} if cfg.imagen_path is not None else {})}
        for cfg in inst.configs
    ]
    archivos_list = [{"nombre": a.nombre, "carpeta": a.carpeta} for a in inst.archivos]

    # Campos comunes que se heredan de la instancia
    estatus = inst.estatus
    tipo_inst = inst.tipo

    match tipo:
        case ComponentType.LIFERAY_BUILD:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display="#" + str(inst.build_id),
                tipo_display="BUILD",  # REQ-CAT-03: era "Liferay"
                contenedor="liferay",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo="build",
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
            )]

        case ComponentType.SQL:
            # 1 fila por script — CONTENEDOR=nombre_bd
            return [
                ComponentConfig(
                    tipo_clave=tipo,
                    nombre_display=script,
                    tipo_display=tipo_inst if tipo_inst else "SQL",  # REQ-CAT-01: inst.tipo o fallback "SQL"
                    contenedor=inst.base_datos,
                    estatus=estatus,
                    scripts=[script],
                    base_datos=inst.base_datos,
                    nombre_servicio=inst.nombre_servicio,
                    configs=configs_list,
                    archivos=archivos_list,
                    build_id=inst.build_id,
                    nombre=inst.nombre,
                    tipo=tipo_inst,
                    crear_pagina=inst.crear_pagina,
                    pagina=inst.pagina,
                    widgets=inst.widgets,
                )
                for script in inst.scripts
            ]

        case ComponentType.API_IIS:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.nombre_servicio,
                tipo_display="API",
                contenedor="IIS",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
                publicar=inst.publicar,
                jenkins=inst.jenkins,
                actualizar_apim=inst.actualizar_apim,
            )]

        case ComponentType.API_DOCKER:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.nombre_servicio,
                tipo_display="API",
                contenedor="Docker",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
                jenkins=inst.jenkins,
                actualizar_apim=inst.actualizar_apim,
            )]

        case ComponentType.BLOB:
            # 1 fila por archivo
            return [
                ComponentConfig(
                    tipo_clave=tipo,
                    nombre_display=archivo.nombre,
                    tipo_display="Blob Storage",
                    contenedor="Azure Blob Storage",
                    estatus=estatus,
                    scripts=inst.scripts,
                    base_datos=inst.base_datos,
                    nombre_servicio=inst.nombre_servicio,
                    configs=configs_list,
                    archivos=[{"nombre": archivo.nombre, "carpeta": archivo.carpeta}],
                    build_id=inst.build_id,
                    nombre=inst.nombre,
                    tipo=tipo_inst,
                    crear_pagina=inst.crear_pagina,
                    pagina=inst.pagina,
                    widgets=inst.widgets,
                )
                for archivo in inst.archivos
            ]

        case ComponentType.LIFERAY:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.nombre,
                tipo_display="Liferay",
                contenedor="Liferay",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
            )]

        case ComponentType.ASSETS:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.archivos[0].nombre if inst.archivos else "Assets",
                tipo_display="Assets",
                contenedor="Assets",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
            )]

        case ComponentType.APIM:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.nombre_servicio,
                tipo_display="API Management",
                contenedor="APIM",
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
            )]

        case _:
            return [ComponentConfig(
                tipo_clave=tipo,
                nombre_display=inst.nombre_servicio or inst.nombre or comp.tipo,
                tipo_display=comp.tipo,
                contenedor=comp.tipo.upper(),
                estatus=estatus,
                scripts=inst.scripts,
                base_datos=inst.base_datos,
                nombre_servicio=inst.nombre_servicio,
                configs=configs_list,
                archivos=archivos_list,
                build_id=inst.build_id,
                nombre=inst.nombre,
                tipo=tipo_inst,
                crear_pagina=inst.crear_pagina,
                pagina=inst.pagina,
                widgets=inst.widgets,
            )]


@router.post("/packages/generate", response_model=GenerateResponse)
def generate_package(req: GenerateRequest) -> GenerateResponse:
    """
    Genera un package completo:
    - Valida que ruta_packages existe
    - Expande instancias de cada componente (multi-instancia)
    - Ordena en orden canónico
    - Crea la estructura de carpetas
    - Genera el .docx
    - Guarda package_meta.json en la raíz del package
    """
    try:
        ruta = Path(req.ruta_packages)
        if not ruta.exists():
            return GenerateResponse(
                ok=False,
                error=f"La ruta no existe: {req.ruta_packages}",
            )

        # Expandir: cada (ComponentIn, InstanceIn) → lista de ComponentConfig (N por instancia)
        raw_configs: list[ComponentConfig] = []
        for comp in req.componentes:
            for inst in comp.instancias:
                raw_configs.extend(_derive_component_config(comp, inst))

        # Ordenar en orden canónico por tipo_clave
        sorted_comps = sorted(
            raw_configs,
            key=lambda c: _CANONICAL_ORDER.index(c.tipo_clave.value)
            if c.tipo_clave.value in _CANONICAL_ORDER
            else 99,
        )

        # Normalizar ambiente a uppercase
        ambiente = req.ambiente.upper()

        # Construir PackageConfig
        config = PackageConfig(
            ticket=req.ticket,
            hu_nombre=req.hu_nombre,
            ambiente=ambiente,
            iteracion=req.iteracion,
            ruta_packages=req.ruta_packages,
            componentes=sorted_comps,
        )

        # Crear estructura de carpetas
        package_dir = create_package_folders(config)

        # ── SQL script copy ──────────────────────────────────────────────────
        copy_errors: list[str] = []
        changes_dir = Path(req.ruta_packages).parent / "changes"
        changes_missing = not changes_dir.exists()
        if changes_missing:
            # Collect which scripts were actually requested before reporting
            any_copy_requested = any(
                any(list(inst.scripts_copiar)[i] if i < len(inst.scripts_copiar) else False
                    for i in range(len(inst.scripts)))
                for comp in req.componentes
                if comp.tipo == "sql"
                for inst in comp.instancias
            )
            if any_copy_requested:
                copy_errors.append(f"Carpeta 'changes' no encontrada: {changes_dir}")
        else:
            for comp in req.componentes:
                if comp.tipo != "sql":
                    continue
                for inst in comp.instancias:
                    flags = list(inst.scripts_copiar)
                    # pad flags to match scripts length
                    while len(flags) < len(inst.scripts):
                        flags.append(False)
                    bd = inst.base_datos or "sin_bd"
                    dest_dir = package_dir / "Componentes" / "SQL" / bd
                    for i, script in enumerate(inst.scripts):
                        if not flags[i]:
                            continue
                        dest_dir.mkdir(parents=True, exist_ok=True)
                        try:
                            found = list(changes_dir.rglob(script))
                            if not found:
                                copy_errors.append(f"Script no encontrado: '{script}'")
                            else:
                                shutil.copy2(str(found[0]), str(dest_dir / script))
                        except Exception as e:
                            copy_errors.append(f"Error copiando '{script}': {e}")

        # ── Publish pipeline ─────────────────────────────────────────────────
        steps: list[StepResult] = []
        pub_outputs: list[str] = []

        opts = _options_manager.load()
        catalog: dict[str, str] = {
            entry.nombre: entry.ruta for entry in opts.api_iis_services
        }

        for comp in sorted_comps:
            if comp.tipo_clave == ComponentType.API_IIS and comp.publicar:
                nombre = comp.nombre_display
                if nombre not in catalog:
                    steps.append(StepResult(
                        label=f"Publicar {nombre}",
                        ok=False,
                        error="Servicio no encontrado en catálogo",
                    ))
                    continue
                ruta_proyecto = catalog[nombre]
                api_dir = package_dir / "Componentes" / "API"
                result = publish_service.publish_api_iis(nombre, ruta_proyecto, api_dir)
                steps.append(StepResult(
                    label=f"Publicar {nombre}",
                    ok=result.ok,
                    error=result.error,
                ))
                if result.ok and result.zip_path:
                    pub_outputs.append(result.zip_path)

        # Generar .docx
        doc_path = package_dir / "Manual" / f"{config.package_name}.docx"
        generate_document(config, doc_path)

        # Guardar meta
        save_package_meta(config, package_dir)

        # Delete package_meta.json — cleanup after generation
        meta_file = package_dir / "package_meta.json"
        if meta_file.exists():
            meta_file.unlink()

        # Recopilar carpetas creadas (relativas al package_dir)
        folders: list[str] = []
        for p in sorted(package_dir.rglob("*")):
            if p.is_dir():
                folders.append(str(p.relative_to(package_dir)))

        return GenerateResponse(
            ok=True,
            package_name=config.package_name,
            package_dir=str(package_dir),
            doc_path=str(doc_path),
            folders_created=folders,
            steps=steps,
            publish_outputs=pub_outputs,
            copy_errors=copy_errors,
        )

    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post("/packages/clone", response_model=CloneResponse)
def clone_package(req: CloneRequest) -> CloneResponse:
    """
    Lee el package_meta.json de un package existente y devuelve los datos
    pre-llenados para crear una nueva iteración.
    """
    source_path = Path(req.source_path)
    meta_path = source_path / "package_meta.json"

    if not meta_path.exists():
        return CloneResponse(
            ok=False,
            error=f"package_meta.json no encontrado en: {req.source_path}",
        )

    try:
        meta = load_package_meta(meta_path)
    except Exception as exc:
        return CloneResponse(
            ok=False,
            error=f"Error al leer package_meta.json: {exc}",
        )

    # Sobrescribir iteracion con la nueva
    prefill = dict(meta)
    prefill["iteracion"] = req.new_iteracion

    return CloneResponse(ok=True, prefill=prefill)


@router.get("/packages/list", response_model=PackageListResponse)
def list_packages(base_dir: str) -> PackageListResponse:
    """
    Lista los subdirectorios en base_dir con metadata de cada package.

    Args:
        base_dir: Ruta del directorio donde buscar packages.

    Returns:
        PackageListResponse con la lista ordenada por fecha desc.
    """
    base = Path(base_dir)

    if not base.exists() or not base.is_dir():
        return PackageListResponse(packages=[])

    items: list[PackageListItem] = []
    for entry in base.iterdir():
        if not entry.is_dir():
            continue

        has_meta = (entry / "package_meta.json").exists()
        stat = entry.stat()
        # st_ctime en Windows = creation time
        created_ts = stat.st_ctime
        created_at = datetime.fromtimestamp(created_ts).isoformat()

        items.append(PackageListItem(
            name=entry.name,
            path=str(entry),
            has_meta=has_meta,
            created_at=created_at,
        ))

    # Ordenar por created_at desc (newest first)
    items.sort(key=lambda x: x.created_at, reverse=True)

    return PackageListResponse(packages=items)
