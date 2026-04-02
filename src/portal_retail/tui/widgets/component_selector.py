"""
Widget de selección de tipos de componente.

Muestra los 8 tipos de ComponentType como una lista de selección múltiple.
Emite el mensaje `ComponentsChanged` cuando la selección cambia.
"""

from __future__ import annotations

from textual.app import ComposeResult
from textual.message import Message
from textual.widget import Widget
from textual.widgets import Label, SelectionList
from textual.widgets.selection_list import Selection

from portal_retail.core.component import (
    COMPONENT_LABELS,
    COMPONENT_ORDER,
    ComponentType,
)


class ComponentSelector(Widget):
    """
    Widget con los 8 tipos de componente como lista de selección múltiple.

    Uso::

        selector = ComponentSelector()
        # Leer selección:
        tipos = selector.selected_components
        # Escuchar cambios:
        def on_component_selector_components_changed(self, event): ...
    """

    DEFAULT_CSS = """
    ComponentSelector {
        height: auto;
        padding: 0 1;
    }
    ComponentSelector Label {
        margin-bottom: 1;
    }
    ComponentSelector SelectionList {
        height: auto;
        border: solid #70AD47;
        padding: 0 1;
    }
    """

    class ComponentsChanged(Message):
        """Emitido cuando el usuario cambia la selección de componentes."""

        def __init__(self, selected: list[ComponentType]) -> None:
            super().__init__()
            self.selected = selected

    def compose(self) -> ComposeResult:
        yield Label("Componentes a incluir:", classes="selector-title")
        selections = [
            Selection(COMPONENT_LABELS.get(ct, ct.value), ct.value, False)
            for ct in COMPONENT_ORDER
        ]
        yield SelectionList(*selections, id="comp_list")

    @property
    def selected_components(self) -> list[ComponentType]:
        """Lista de ComponentType con selección activa."""
        lista = self.query_one("#comp_list", SelectionList)
        return [ComponentType(v) for v in lista.selected]

    def on_selection_list_selected_changed(self, _event: SelectionList.SelectedChanged) -> None:
        """Re-emite ComponentsChanged con la lista actualizada."""
        self.post_message(self.ComponentsChanged(self.selected_components))

    def set_components(self, types: list[ComponentType]) -> None:
        """
        Activa los ítems de los tipos indicados (para clone mode).

        Args:
            types: Lista de ComponentType a marcar como seleccionados.
        """
        lista = self.query_one("#comp_list", SelectionList)
        for ct in ComponentType:
            if ct in types:
                lista.select(ct.value)
            else:
                lista.deselect(ct.value)
