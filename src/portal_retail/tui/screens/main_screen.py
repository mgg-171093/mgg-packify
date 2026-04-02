"""
Pantalla de bienvenida / menú principal.

Muestra el título y 3 botones: "Nuevo Package", "Clonar Package", "Salir".
"""

from __future__ import annotations

from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Label


class MainScreen(Screen):
    """
    Pantalla principal de la app Portal Retail.

    Muestra el menú con 3 acciones: crear nuevo package, clonar uno
    existente, o salir.
    """

    BINDINGS = [
        ("n", "new_package", "Nuevo"),
        ("c", "clone_package", "Clonar"),
        ("q", "quit", "Salir"),
    ]

    DEFAULT_CSS = """
    MainScreen {
        align: center middle;
    }
    MainScreen #title {
        content-align: center middle;
        text-align: center;
        color: #70AD47;
        text-style: bold;
        margin-bottom: 2;
        width: 100%;
    }
    MainScreen #subtitle {
        content-align: center middle;
        text-align: center;
        color: $text-muted;
        margin-bottom: 3;
        width: 100%;
    }
    MainScreen #menu {
        align: center middle;
        height: auto;
        width: 40;
    }
    MainScreen Button {
        width: 100%;
        margin-bottom: 1;
    }
    MainScreen #btn-new {
        background: #70AD47;
        color: white;
    }
    MainScreen #btn-clone {
        background: #4472C4;
        color: white;
    }
    MainScreen #btn-exit {
        background: $surface;
        color: $text-muted;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        yield Label("mgg-packgen — Generador de Packages v2", id="title")
        yield Label("Skandia México  |  Equipo de Desarrollo", id="subtitle")
        from textual.containers import Container
        with Container(id="menu"):
            yield Button("  Nuevo Package", id="btn-new", variant="success")
            yield Button("  Clonar Package", id="btn-clone", variant="primary")
            yield Button("  Salir", id="btn-exit", variant="default")
        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-new":
            self.action_new_package()
        elif event.button.id == "btn-clone":
            self.action_clone_package()
        elif event.button.id == "btn-exit":
            self.action_quit()

    def action_new_package(self) -> None:
        """Navega a la pantalla de creación de nuevo package."""
        from portal_retail.tui.screens.package_screen import PackageScreen
        self.app.push_screen(PackageScreen())

    def action_clone_package(self) -> None:
        """Navega a la pantalla de clon de package existente."""
        from portal_retail.tui.screens.clone_screen import CloneScreen
        self.app.push_screen(CloneScreen())

    def action_quit(self) -> None:
        """Sale de la aplicación."""
        self.app.exit()
