"""
Pantalla de clonado de package existente.

Lee `Manual/package_meta.json` del directorio ingresado, pre-llena
el formulario de PackageScreen con los datos del package anterior,
y solo requiere ingresar la nueva iteración.
"""

from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Container, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Input, Label

from portal_retail.core.component import ComponentType


class CloneScreen(Screen):
    """
    Pantalla de clon de package existente.

    El usuario ingresa la ruta al directorio del package anterior.
    La app lee package_meta.json, pre-llena PackageScreen con esos datos
    y solo requiere la nueva iteración.
    """

    BINDINGS = [
        ("escape", "go_back", "Volver"),
    ]

    DEFAULT_CSS = """
    CloneScreen {
        align: center middle;
    }
    CloneScreen #container {
        width: 70;
        height: auto;
        padding: 2 3;
        background: $surface;
        border: solid #70AD47;
    }
    CloneScreen .title {
        color: #70AD47;
        text-style: bold;
        margin-bottom: 1;
    }
    CloneScreen .field-label {
        color: $text-muted;
        margin-top: 1;
    }
    CloneScreen #meta-preview {
        color: $text-muted;
        height: auto;
        margin-top: 1;
    }
    CloneScreen #error-msg {
        color: red;
        text-style: bold;
        height: 1;
    }
    CloneScreen #btn-row {
        height: 3;
        align: left middle;
        margin-top: 1;
    }
    CloneScreen #btn-load {
        background: #4472C4;
        color: white;
        margin-right: 1;
    }
    CloneScreen #btn-back {
        background: $surface;
        color: $text-muted;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Vertical(id="container"):
            yield Label("Clonar Package Existente", classes="title")

            yield Label("Ruta al directorio del package anterior:", classes="field-label")
            yield Input(
                placeholder=r"C:\Packages\MX01-12345-PortalRetail_QA-01",
                id="inp_source_path",
            )

            yield Label("Nueva iteración (obligatoria):", classes="field-label")
            yield Input(
                placeholder="02",
                id="inp_new_iter",
            )

            yield Label("", id="meta-preview")
            yield Label("", id="error-msg")

            with Container(id="btn-row"):
                yield Button("Cargar y Continuar", id="btn-load", variant="primary")
                yield Button("Volver (Esc)", id="btn-back", variant="default")

        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-load":
            self._load_and_continue()
        elif event.button.id == "btn-back":
            self.action_go_back()

    def action_go_back(self) -> None:
        self.app.pop_screen()

    def _load_and_continue(self) -> None:
        """Lee package_meta.json y abre PackageScreen pre-llenado."""
        error_label: Label = self.query_one("#error-msg", Label)
        preview_label: Label = self.query_one("#meta-preview", Label)
        error_label.update("")
        preview_label.update("")

        source_path_str = self.query_one("#inp_source_path", Input).value.strip()
        new_iter = self.query_one("#inp_new_iter", Input).value.strip()

        # ── Validar campos ──────────────────────────────────────────────────
        if not source_path_str:
            error_label.update("⚠ Ingresá la ruta al package existente.")
            return
        if not new_iter:
            error_label.update("⚠ La nueva iteración es obligatoria.")
            return

        source_path = Path(source_path_str)
        if not source_path.exists():
            error_label.update(f"⚠ El directorio no existe: {source_path}")
            return

        meta_path = source_path / "package_meta.json"
        if not meta_path.exists():
            error_label.update(
                f"⚠ No se encontró package_meta.json en:\n  {meta_path}"
            )
            return

        # ── Leer metadata ───────────────────────────────────────────────────
        try:
            from portal_retail.services.folder_service import load_package_meta
            meta = load_package_meta(meta_path)
        except Exception as exc:  # noqa: BLE001
            error_label.update(f"⚠ Error al leer package_meta.json: {exc}")
            return

        # ── Recuperar tipos de componente ───────────────────────────────────
        tipos: list[ComponentType] = []
        for comp_dict in meta.get("componentes", []):
            tipo_str = comp_dict.get("tipo_clave", "")
            try:
                tipos.append(ComponentType(tipo_str))
            except ValueError:
                pass  # ignorar tipos desconocidos

        # ── Construir prefill ───────────────────────────────────────────────
        prefill = {
            "ticket": meta.get("ticket", ""),
            "hu_nombre": meta.get("hu_nombre", ""),
            "ambiente": meta.get("ambiente", "QA"),
            "iteracion": new_iter,
            "ruta_packages": meta.get("ruta_packages", ""),
            "componentes": tipos,
        }

        preview_label.update(
            f"Package encontrado: {meta.get('ticket', '')} — "
            f"{meta.get('ambiente', '')} — iter {meta.get('iteracion', '')}\n"
            f"Componentes: {len(tipos)} | Nueva iter: {new_iter}"
        )

        # ── Navegar a PackageScreen pre-llenado ────────────────────────────
        from portal_retail.tui.screens.package_screen import PackageScreen
        self.app.push_screen(PackageScreen(prefill=prefill))
