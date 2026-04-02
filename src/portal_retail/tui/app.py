"""
Aplicación principal Portal Retail — TUI con Textual.

PortalRetailApp es el punto de entrada de la interfaz. Pushea MainScreen
al montar y expone los bindings globales de navegación.
"""

from __future__ import annotations

from textual.app import App

from portal_retail.tui.screens.main_screen import MainScreen


class PortalRetailApp(App):
    """
    App principal del Portal Retail v2.

    Lifecycle::

        on_mount → push MainScreen
        MainScreen → push PackageScreen | CloneScreen
        PackageScreen / CloneScreen → pop → vuelve a MainScreen
    """

    CSS_PATH = "app.tcss"

    TITLE = "mgg-packgen — Generador de Packages v2"
    SUB_TITLE = "Skandia México"

    BINDINGS = [
        ("ctrl+c", "quit", "Salir"),
    ]

    def on_mount(self) -> None:
        """Arranca con la pantalla principal."""
        self.push_screen(MainScreen())
