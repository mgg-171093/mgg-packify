"""
Widget de configuración de servidores QA y PROD.

Muestra inputs para api, bd, blob y liferay. Puede pre-cargarse desde
un SettingsManager para reutilizar los valores de la sesión anterior.
"""

from __future__ import annotations

from textual.app import ComposeResult
from textual.widget import Widget
from textual.widgets import Input, Label

from portal_retail.core.package import ServerConfig


class ServerForm(Widget):
    """
    Formulario de campos de servidor QA + PROD.

    Expone las propiedades ``qa_server`` y ``prod_server`` para leer
    los valores actuales de los inputs, y el método ``load_from_settings``
    para pre-cargarlos desde la persistencia.
    """

    DEFAULT_CSS = """
    ServerForm {
        height: auto;
        padding: 0 1;
    }
    ServerForm Label {
        margin-top: 1;
        color: $text-muted;
    }
    ServerForm .env-label {
        margin-top: 1;
        color: #70AD47;
        text-style: bold;
    }
    ServerForm Input {
        margin-bottom: 0;
    }
    """

    def __init__(self, ambiente: str = "QA", **kwargs) -> None:
        """
        Args:
            ambiente: 'QA' o 'PROD' — determina qué sección mostrar.
        """
        super().__init__(**kwargs)
        self._ambiente = ambiente.upper()

    def compose(self) -> ComposeResult:
        env = self._ambiente
        yield Label(f"— Servidores {env} —", classes="env-label")
        yield Label("API / Servicios:")
        yield Input(placeholder=f"Servidor API {env}", id=f"{env.lower()}_api")
        yield Label("Base de Datos:")
        yield Input(placeholder=f"Servidor BD {env}", id=f"{env.lower()}_bd")
        yield Label("Blob Storage:")
        yield Input(placeholder=f"Cuenta Blob {env}", id=f"{env.lower()}_blob")
        yield Label("Liferay:")
        yield Input(placeholder=f"Servidor Liferay {env}", id=f"{env.lower()}_liferay")

    # ── Propiedades de lectura ────────────────────────────────────────────────

    def _get_val(self, suffix: str) -> str:
        """Lee el valor de un input por sufijo."""
        env = self._ambiente.lower()
        try:
            return self.query_one(f"#{env}_{suffix}", Input).value.strip()
        except Exception:
            return ""

    @property
    def qa_server(self) -> str:
        """Valor del campo API (para compatibilidad con código que espera .qa_server)."""
        return self._get_val("api")

    @property
    def prod_server(self) -> str:
        """Valor del campo API (para compatibilidad con código que espera .prod_server)."""
        return self._get_val("api")

    def get_server_config(self) -> ServerConfig:
        """Construye y devuelve el ServerConfig con los valores actuales."""
        return ServerConfig(
            api=self._get_val("api"),
            bd=self._get_val("bd"),
            blob=self._get_val("blob"),
            liferay=self._get_val("liferay"),
        )

    # ── Pre-carga desde settings ──────────────────────────────────────────────

    def load_from_settings(self, server_config: ServerConfig) -> None:
        """
        Pre-carga los inputs con los valores del ServerConfig dado.

        Args:
            server_config: ServerConfig con los valores a pre-cargar.
        """
        env = self._ambiente.lower()
        mapping = {
            f"{env}_api": server_config.api,
            f"{env}_bd": server_config.bd,
            f"{env}_blob": server_config.blob,
            f"{env}_liferay": server_config.liferay,
        }
        for field_id, value in mapping.items():
            try:
                self.query_one(f"#{field_id}", Input).value = value
            except Exception:
                pass
