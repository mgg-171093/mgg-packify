"""
Persistencia de configuración del usuario.

Guarda y carga la configuración de servidores y last_used en
%APPDATA%\\portal_retail\\config.json (Windows) o
~/.config/portal_retail/config.json (Unix) usando platformdirs.

Si el archivo no existe o está corrupto, devuelve defaults vacíos
silenciosamente.
"""

from __future__ import annotations

import json
import logging
from pathlib import Path

from platformdirs import user_data_dir

from portal_retail.core.package import ServerConfig

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# SCHEMA DEL CONFIG JSON (versión 1)
# ─────────────────────────────────────────────────────────────────────────────
# {
#   "version": 1,
#   "servers": {
#     "qa":   { "api": "", "bd": "", "blob": "", "liferay": "" },
#     "prod": { "api": "", "bd": "", "blob": "", "liferay": "" }
#   },
#   "last_used": {
#     "ticket": "",
#     "hu_nombre": "",
#     "ambiente": "QA",
#     "iteracion": "01",
#     "hu_carpeta": "",
#     "tipo_carpeta": "1.-User-Stories"
#   }
# }

_APP_NAME = "portal_retail"
_CONFIG_FILE = "config.json"
_SCHEMA_VERSION = 1

_DEFAULT_SERVERS: dict = {
    "qa":   {"api": "", "bd": "", "blob": "", "liferay": ""},
    "prod": {"api": "", "bd": "", "blob": "", "liferay": ""},
}

_DEFAULT_LAST_USED: dict = {
    "ticket": "",
    "hu_nombre": "",
    "ambiente": "QA",
    "iteracion": "01",
    "hu_carpeta": "",
    "tipo_carpeta": "1.-User-Stories",
}


def _default_config() -> dict:
    """Devuelve la configuración por defecto."""
    import copy
    return {
        "version": _SCHEMA_VERSION,
        "servers": copy.deepcopy(_DEFAULT_SERVERS),
        "last_used": copy.deepcopy(_DEFAULT_LAST_USED),
    }


def _config_path() -> Path:
    """Devuelve la ruta al archivo de configuración del usuario."""
    data_dir = Path(user_data_dir(appname=_APP_NAME, appauthor=False))
    return data_dir / _CONFIG_FILE


# ─────────────────────────────────────────────────────────────────────────────
# CLASE PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────

class SettingsManager:
    """
    Gestiona la persistencia de configuración del usuario.

    Usa platformdirs para determinar la ruta del archivo de configuración
    según el sistema operativo. Si el archivo no existe o está corrupto,
    devuelve defaults vacíos silenciosamente.
    """

    def __init__(self, config_path: Path | None = None) -> None:
        """
        Inicializa el manager.

        Args:
            config_path: Ruta personalizada al archivo de configuración.
                         Si es None, usa la ruta por defecto de platformdirs.
                         Útil para tests (usar tmp_path).
        """
        self._path = config_path or _config_path()
        self._data: dict = _default_config()

    # ── Lectura ──────────────────────────────────────────────────────────────

    def load(self) -> SettingsData:
        """
        Carga la configuración desde disco.

        Si el archivo no existe, devuelve defaults vacíos sin error.
        Si el JSON está corrupto, resetea a defaults silenciosamente.

        Returns:
            SettingsData con los valores cargados (o defaults).
        """
        if not self._path.exists():
            self._data = _default_config()
            return SettingsData(self._data)

        try:
            with self._path.open("r", encoding="utf-8") as f:
                loaded = json.load(f)
            # Merge con defaults para tolerar campos faltantes en versiones viejas
            self._data = _merge_with_defaults(loaded)
        except (json.JSONDecodeError, OSError, TypeError, ValueError) as exc:
            logger.warning("Config corrupta o ilegible (%s) — usando defaults.", exc)
            self._data = _default_config()

        return SettingsData(self._data)

    def get_server_config(self, ambiente: str) -> ServerConfig:
        """
        Devuelve el ServerConfig para el ambiente dado ('QA' o 'PROD').

        Args:
            ambiente: 'QA' o 'PROD' (case-insensitive).

        Returns:
            ServerConfig con los valores persistidos.
        """
        key = ambiente.lower()
        srv = self._data.get("servers", {}).get(key, {})
        return ServerConfig(
            api=srv.get("api", ""),
            bd=srv.get("bd", ""),
            blob=srv.get("blob", ""),
            liferay=srv.get("liferay", ""),
        )

    # ── Escritura ─────────────────────────────────────────────────────────────

    def save(self, config: ServerConfig, ambiente: str = "QA") -> None:
        """
        Guarda el ServerConfig para el ambiente dado.

        Args:
            config: ServerConfig con los valores a persistir.
            ambiente: 'QA' o 'PROD'.
        """
        key = ambiente.lower()
        if "servers" not in self._data:
            import copy
            self._data["servers"] = copy.deepcopy(_DEFAULT_SERVERS)

        self._data["servers"][key] = {
            "api": config.api,
            "bd": config.bd,
            "blob": config.blob,
            "liferay": config.liferay,
        }
        self._write()

    def save_last_used(self, last_used: dict) -> None:
        """
        Persiste el campo last_used en la configuración.

        Args:
            last_used: Dict con los campos ticket, hu_nombre, ambiente,
                       iteracion, hu_carpeta, tipo_carpeta.
        """
        self._data["last_used"] = {**_DEFAULT_LAST_USED, **last_used}
        self._write()

    def get_last_used(self) -> dict:
        """Devuelve el dict de last_used (con defaults si no existe)."""
        import copy
        return copy.deepcopy(self._data.get("last_used", _DEFAULT_LAST_USED))

    # ── Privado ───────────────────────────────────────────────────────────────

    def _write(self) -> None:
        """Escribe self._data en disco, creando el directorio si es necesario."""
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            with self._path.open("w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2, ensure_ascii=False)
        except OSError as exc:
            logger.error("No se pudo escribir la configuración: %s", exc)


# ─────────────────────────────────────────────────────────────────────────────
# VALUE OBJECT DE RETORNO
# ─────────────────────────────────────────────────────────────────────────────

class SettingsData:
    """Datos de configuración cargados desde disco."""

    def __init__(self, data: dict) -> None:
        self._data = data

    @property
    def qa_servers(self) -> ServerConfig:
        srv = self._data.get("servers", {}).get("qa", {})
        return ServerConfig(
            api=srv.get("api", ""),
            bd=srv.get("bd", ""),
            blob=srv.get("blob", ""),
            liferay=srv.get("liferay", ""),
        )

    @property
    def prod_servers(self) -> ServerConfig:
        srv = self._data.get("servers", {}).get("prod", {})
        return ServerConfig(
            api=srv.get("api", ""),
            bd=srv.get("bd", ""),
            blob=srv.get("blob", ""),
            liferay=srv.get("liferay", ""),
        )

    @property
    def last_used(self) -> dict:
        import copy
        return copy.deepcopy(self._data.get("last_used", _DEFAULT_LAST_USED))


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _merge_with_defaults(loaded: dict) -> dict:
    """
    Combina los datos cargados con los defaults para tolerar campos
    faltantes en versiones anteriores del schema.
    """
    result = _default_config()
    if not isinstance(loaded, dict):
        return result

    # servers por ambiente
    for env in ("qa", "prod"):
        srv = loaded.get("servers", {}).get(env)
        if isinstance(srv, dict):
            for k in ("api", "bd", "blob", "liferay"):
                if k in srv:
                    result["servers"][env][k] = str(srv[k])

    # last_used
    lu = loaded.get("last_used")
    if isinstance(lu, dict):
        for k in _DEFAULT_LAST_USED:
            if k in lu:
                result["last_used"][k] = str(lu[k])

    return result
