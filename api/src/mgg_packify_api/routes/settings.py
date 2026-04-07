"""
Rutas GET /settings y PUT /settings — configuración de servidores y last_used.
Rutas GET /settings/options y PUT /settings/options — listas de opciones configurables.
"""

from __future__ import annotations

from fastapi import APIRouter

from mgg_packify_api.schemas.options import OptionsSchema
from mgg_packify_api.schemas.settings import (
    SettingsSaveResponse,
    SettingsSchema,
    ServerSettings,
    ServersSettings,
    LastUsedSettings,
)
from mgg_packify_api.services.options_service import OptionsManager
from mgg_packify_api.services.package import ServerConfig
from mgg_packify_api.services.settings_service import SettingsManager

router = APIRouter()

# Singleton del manager — se crea una vez al importar el módulo
_manager = SettingsManager()

# Singleton del options manager
_options_manager = OptionsManager()


def _get_manager() -> SettingsManager:
    """Devuelve el manager singleton. Puede reemplazarse en tests."""
    return _manager


def _get_options_manager() -> OptionsManager:
    """Devuelve el options manager singleton. Puede reemplazarse en tests."""
    return _options_manager


@router.get("/settings", response_model=SettingsSchema)
def get_settings() -> SettingsSchema:
    """
    Devuelve la configuración persistida del usuario.

    Si no existe config.json, devuelve defaults (todos vacíos, ambiente=QA,
    iteracion=01).
    """
    manager = _get_manager()
    data = manager.load()

    qa = data.qa_servers
    prod = data.prod_servers
    lu = data.last_used

    return SettingsSchema(
        servers=ServersSettings(
            qa=ServerSettings(api=qa.api, bd=qa.bd, blob=qa.blob, liferay=qa.liferay),
            prod=ServerSettings(api=prod.api, bd=prod.bd, blob=prod.blob, liferay=prod.liferay),
        ),
        last_used=LastUsedSettings(
            ticket=lu.get("ticket", ""),
            hu_nombre=lu.get("hu_nombre", ""),
            ambiente=lu.get("ambiente", "QA"),
            iteracion=lu.get("iteracion", "01"),
            ruta_packages=lu.get("ruta_packages", ""),
        ),
    )


@router.put("/settings", response_model=SettingsSaveResponse)
def put_settings(body: SettingsSchema) -> SettingsSaveResponse:
    """
    Guarda la configuración de servidores y last_used.

    Args:
        body: SettingsSchema con los valores a persistir.

    Returns:
        SettingsSaveResponse con ok=True.
    """
    manager = _get_manager()

    qa_config = ServerConfig(
        api=body.servers.qa.api,
        bd=body.servers.qa.bd,
        blob=body.servers.qa.blob,
        liferay=body.servers.qa.liferay,
    )
    prod_config = ServerConfig(
        api=body.servers.prod.api,
        bd=body.servers.prod.bd,
        blob=body.servers.prod.blob,
        liferay=body.servers.prod.liferay,
    )
    last_used = {
        "ticket": body.last_used.ticket,
        "hu_nombre": body.last_used.hu_nombre,
        "ambiente": body.last_used.ambiente,
        "iteracion": body.last_used.iteracion,
        "ruta_packages": body.last_used.ruta_packages,
    }

    manager.save_all(qa_config, prod_config, last_used)
    return SettingsSaveResponse(ok=True)


@router.get("/settings/options", response_model=OptionsSchema)
def get_options() -> OptionsSchema:
    """
    Devuelve las listas de opciones configurables del usuario.

    Si no existe options.json, devuelve defaults (REQ-OPT-01).
    """
    return _get_options_manager().load()


@router.put("/settings/options", response_model=OptionsSchema)
def put_options(body: OptionsSchema) -> OptionsSchema:
    """
    Guarda las listas de opciones configurables y devuelve el valor persistido.

    Args:
        body: OptionsSchema con los valores a persistir.

    Returns:
        OptionsSchema con los valores guardados (REQ-OPT-02).
    """
    manager = _get_options_manager()
    manager.save(body)
    return manager.load()
