"""
Pydantic v2 models para settings (configuración de servidores y last_used).
"""

from __future__ import annotations

from pydantic import BaseModel


class ServerSettings(BaseModel):
    api: str = ""
    bd: str = ""
    blob: str = ""
    liferay: str = ""


class ServersSettings(BaseModel):
    qa: ServerSettings = ServerSettings()
    prod: ServerSettings = ServerSettings()


class LastUsedSettings(BaseModel):
    ticket: str = ""
    hu_nombre: str = ""
    ambiente: str = "QA"
    iteracion: str = "01"
    ruta_packages: str = ""


class SettingsSchema(BaseModel):
    servers: ServersSettings = ServersSettings()
    last_used: LastUsedSettings = LastUsedSettings()


class SettingsSaveResponse(BaseModel):
    ok: bool
