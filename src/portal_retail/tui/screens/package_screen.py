"""
Pantalla de creación de nuevo package.

Formulario completo: ticket, HU, ambiente, iteración, ruta, componentes
y detalles específicos de cada componente seleccionado (multi-instancia).

Diseño del formulario dinámico
──────────────────────────────
Cada ComponentType seleccionado genera N instancias (excepto LIFERAY_BUILD que
es única). Cada instancia tiene sus propios campos según el tipo:

  LIFERAY_BUILD  → Build ID (único, sin botón +)
  SQL            → nombre script + base de datos  (+ N instancias)
  API_IIS        → nombre servicio  + N configs (clave/valor)  (+ N instancias)
  API_DOCKER     → nombre servicio  + N configs (clave/valor)  (+ N instancias)
  APIM           → nombre servicio                             (+ N instancias)
  LIFERAY        → nombre remote app                           (+ N instancias)
  BLOB           → nombre archivo + carpeta                    (+ N instancias)
  ASSETS         → nombre archivo                              (+ N instancias)

Al presionar Generar se leen todos los widgets por ID y se construye la
lista de ComponentConfig para el PackageConfig.
"""

from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, VerticalScroll
from textual.screen import Screen
from textual.widgets import (
    Button,
    Footer,
    Header,
    Input,
    Label,
    Select,
)

from portal_retail.config.settings import SettingsManager
from portal_retail.core.component import (
    COMPONENT_LABELS,
    TIPO_DISPLAY,
    ComponentConfig,
    ComponentType,
)
from portal_retail.core.package import PackageConfig
from portal_retail.tui.widgets.component_selector import ComponentSelector

# Tipos que permiten múltiples instancias
_MULTI_INSTANCE = {
    ComponentType.SQL,
    ComponentType.API_IIS,
    ComponentType.API_DOCKER,
    ComponentType.APIM,
    ComponentType.LIFERAY,
    ComponentType.BLOB,
    ComponentType.ASSETS,
}

# Tipos que soportan configs internas (pares clave/valor)
_HAS_CONFIGS = {ComponentType.API_IIS, ComponentType.API_DOCKER}

# ─────────────────────────────────────────────────────────────────────────────
# ID HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _iid(ct: ComponentType, idx: int, field: str) -> str:
    """ID para un campo de una instancia: det_{tipo}_{idx}_{field}."""
    return f"det_{ct.value}_{idx}_{field}"


def _cfg_id(ct: ComponentType, inst_idx: int, cfg_idx: int, field: str) -> str:
    """ID para un par clave/valor de configs: cfg_{tipo}_{inst}_{cfg}_{field}."""
    return f"cfg_{ct.value}_{inst_idx}_{cfg_idx}_{field}"


def _add_btn_id(ct: ComponentType) -> str:
    """ID del botón 'Agregar instancia' para un tipo."""
    return f"btn_add_{ct.value}"


def _add_cfg_btn_id(ct: ComponentType, inst_idx: int) -> str:
    """ID del botón 'Agregar config' dentro de una instancia."""
    return f"btn_addcfg_{ct.value}_{inst_idx}"


# ─────────────────────────────────────────────────────────────────────────────
# ESTADO MUTABLE DEL FORMULARIO
# ─────────────────────────────────────────────────────────────────────────────

class _FormState:
    """
    Lleva la cuenta de cuántas instancias hay por tipo y cuántas configs
    hay por instancia de API. Es necesario para saber qué IDs existen
    al leer el formulario en action_generate.
    """

    def __init__(self) -> None:
        # tipo → número de instancias montadas
        self.instance_count: dict[ComponentType, int] = {}
        # (tipo, inst_idx) → número de configs montadas
        self.config_count: dict[tuple[ComponentType, int], int] = {}

    def reset(self) -> None:
        self.instance_count.clear()
        self.config_count.clear()

    def remove_type(self, ct: ComponentType) -> None:
        """Elimina el estado de un tipo y todas sus configs."""
        self.instance_count.pop(ct, None)
        keys_to_del = [k for k in self.config_count if k[0] == ct]
        for k in keys_to_del:
            del self.config_count[k]

    def instances(self, ct: ComponentType) -> int:
        return self.instance_count.get(ct, 0)

    def add_instance(self, ct: ComponentType) -> int:
        """Incrementa el contador y devuelve el nuevo índice (0-based)."""
        idx = self.instance_count.get(ct, 0)
        self.instance_count[ct] = idx + 1
        return idx

    def configs(self, ct: ComponentType, inst_idx: int) -> int:
        return self.config_count.get((ct, inst_idx), 0)

    def add_config(self, ct: ComponentType, inst_idx: int) -> int:
        key = (ct, inst_idx)
        idx = self.config_count.get(key, 0)
        self.config_count[key] = idx + 1
        return idx


# ─────────────────────────────────────────────────────────────────────────────
# PANTALLA PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────

class PackageScreen(Screen):
    """Formulario completo para generar un nuevo package de instalación."""

    BINDINGS = [
        ("escape", "go_back", "Volver"),
        ("ctrl+g", "generate", "Generar"),
    ]

    DEFAULT_CSS = """
    PackageScreen {
        layout: vertical;
    }
    PackageScreen VerticalScroll {
        width: 100%;
        height: 1fr;
        padding: 1 2;
    }
    PackageScreen .section-title {
        color: #70AD47;
        text-style: bold;
        margin-top: 1;
        margin-bottom: 0;
    }
    PackageScreen .field-label {
        color: $text-muted;
        margin-top: 1;
    }
    PackageScreen .inst-header {
        color: #AAAAAA;
        text-style: bold italic;
        margin-top: 1;
    }
    PackageScreen .cfg-label {
        color: $text-muted;
        margin-top: 0;
    }
    PackageScreen Input {
        margin-bottom: 0;
    }
    PackageScreen .btn-add-inst {
        margin-top: 1;
        background: #264D1A;
        color: #70AD47;
        min-width: 22;
        height: 3;
    }
    PackageScreen .btn-add-cfg {
        margin-top: 0;
        background: #1A1A2E;
        color: #8080FF;
        min-width: 20;
        height: 3;
    }
    PackageScreen .cfg-row {
        height: auto;
        margin-top: 0;
    }
    PackageScreen .cfg-row Input {
        width: 1fr;
    }
    PackageScreen #comp-details-container {
        height: auto;
    }
    PackageScreen #error-msg {
        color: red;
        text-style: bold;
        height: 1;
    }
    PackageScreen #success-msg {
        color: #70AD47;
        text-style: bold;
        height: auto;
        display: none;
    }
    PackageScreen #btn-row {
        height: 3;
        align: left middle;
        margin-top: 1;
    }
    PackageScreen #btn-generate {
        background: #70AD47;
        color: white;
        margin-right: 1;
    }
    PackageScreen #btn-back {
        background: $surface;
        color: $text-muted;
    }
    """

    def __init__(self, prefill: dict | None = None, **kwargs) -> None:
        super().__init__(**kwargs)
        self._prefill = prefill or {}
        self._state = _FormState()
        # Set de tipos actualmente montados (para diff incremental)
        self._active_tipos: set[ComponentType] = set()
        # Orden canónico de tipos activos (para insertar en posición correcta)
        self._active_order: list[ComponentType] = []

    # ── Composición ──────────────────────────────────────────────────────────

    def compose(self) -> ComposeResult:
        settings = SettingsManager()
        data = settings.load()
        lu = data.last_used

        yield Header(show_clock=True)

        with VerticalScroll():
            yield Label("Datos del Package", classes="section-title")

            yield Label("Ticket (ej: MX01-274906):", classes="field-label")
            yield Input(
                value=self._prefill.get("ticket", lu.get("ticket", "")),
                placeholder="MX01-XXXXXX",
                id="inp_ticket",
            )

            yield Label("Nombre HU / Fix / Spike (opcional):", classes="field-label")
            yield Input(
                value=self._prefill.get("hu_nombre", lu.get("hu_nombre", "")),
                placeholder="ej: Portal Retail - Cotizador v2",
                id="inp_hu",
            )

            yield Label("Ambiente:", classes="field-label")
            amb_default = self._prefill.get("ambiente", lu.get("ambiente", "QA"))
            yield Select(
                options=[("QA", "QA"), ("PROD", "PROD")],
                value=amb_default,
                id="sel_ambiente",
            )

            yield Label("Iteración:", classes="field-label")
            yield Input(
                value=self._prefill.get("iteracion", lu.get("iteracion", "01")),
                placeholder="01",
                id="inp_iteracion",
            )

            yield Label("Ruta de packages (directorio base):", classes="field-label")
            yield Input(
                value=self._prefill.get("ruta_packages", lu.get("ruta_packages", "")),
                placeholder=r"C:\Packages",
                id="inp_ruta",
            )

            yield ComponentSelector(id="comp_selector")

            yield Label(
                "Detalles de componentes",
                classes="section-title",
                id="lbl-details-title",
            )
            yield Container(id="comp-details-container")

            yield Label("", id="error-msg")
            yield Label("", id="success-msg")

            with Container(id="btn-row"):
                yield Button("Generar (Ctrl+G)", id="btn-generate", variant="success")
                yield Button("Volver (Esc)", id="btn-back", variant="default")

        yield Footer()

    # ── Lifecycle ─────────────────────────────────────────────────────────────

    async def on_ready(self) -> None:
        if "componentes" in self._prefill:
            selector: ComponentSelector = self.query_one(
                "#comp_selector", ComponentSelector
            )
            selector.set_components(self._prefill["componentes"])
            await self._sync_component_details(self._prefill["componentes"])
        else:
            self.query_one("#lbl-details-title", Label).styles.display = "none"

    # ── Reacción a cambios de selección ──────────────────────────────────────

    async def on_component_selector_components_changed(
        self, event: ComponentSelector.ComponentsChanged
    ) -> None:
        await self._sync_component_details(event.selected)

    async def _sync_component_details(
        self, tipos: list[ComponentType]
    ) -> None:
        """
        Actualiza la sección de detalles de forma incremental (diff).

        Solo agrega los tipos nuevos y elimina los que se desmarcaron.
        Los tipos que ya estaban montados NO se tocan — sus inputs conservan
        el contenido capturado por el usuario.
        """
        container = self.query_one("#comp-details-container", Container)
        lbl_title = self.query_one("#lbl-details-title", Label)

        new_set = set(tipos)
        old_set = self._active_tipos

        # Tipos a eliminar (se desmarcaron)
        for ct in list(old_set - new_set):
            try:
                tc = self.query_one(f"#tc_{ct.value}", Container)
                await tc.remove()
            except Exception:  # noqa: BLE001
                pass
            self._state.remove_type(ct)
            self._active_tipos.discard(ct)
            if ct in self._active_order:
                self._active_order.remove(ct)

        # Tipos a agregar (se marcaron ahora)
        # Los montamos en orden canónico respetando los ya existentes
        from portal_retail.core.component import COMPONENT_ORDER
        for ct in COMPONENT_ORDER:
            if ct not in new_set or ct in old_set:
                continue  # ya existe o no está seleccionado

            type_container = Container(id=f"tc_{ct.value}")

            # Insertar en la posición canónica dentro del container
            # Buscar el primer tipo activo que va DESPUÉS de ct en COMPONENT_ORDER
            inserted = False
            ct_order_idx = COMPONENT_ORDER.index(ct)
            for later_ct in COMPONENT_ORDER[ct_order_idx + 1 :]:
                if later_ct in self._active_tipos:
                    try:
                        later_tc = self.query_one(
                            f"#tc_{later_ct.value}", Container
                        )
                        await container.mount(type_container, before=later_tc)
                        inserted = True
                        break
                    except Exception:  # noqa: BLE001
                        pass
            if not inserted:
                await container.mount(type_container)

            await self._mount_instance(ct, type_container)

            if ct in _MULTI_INSTANCE:
                label_tipo = COMPONENT_LABELS.get(ct, ct.value)
                btn = Button(
                    f"+ Agregar otro {label_tipo}",
                    id=_add_btn_id(ct),
                    classes="btn-add-inst",
                )
                await type_container.mount(btn)

            self._active_tipos.add(ct)
            self._active_order.append(ct)

        if self._active_tipos:
            lbl_title.styles.display = "block"
        else:
            lbl_title.styles.display = "none"

    async def _mount_instance(
        self,
        ct: ComponentType,
        type_container: Container,
        *,
        focus_new: bool = False,
    ) -> None:
        """Monta los widgets de una nueva instancia del tipo dado."""
        idx = self._state.add_instance(ct)
        label_tipo = COMPONENT_LABELS.get(ct, ct.value)

        widgets: list = []

        if ct == ComponentType.LIFERAY_BUILD:
            widgets.append(Label(f"▸ {label_tipo}", classes="inst-header"))
            widgets.append(
                Label("Build ID (nº de pipeline, ej: 7957):", classes="field-label")
            )
            widgets.append(
                Input(placeholder="7957", id=_iid(ct, idx, "build_id"))
            )

        elif ct == ComponentType.SQL:
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label("Nombre del script SQL (ej: 01_Script.sql):", classes="field-label")
            )
            widgets.append(
                Input(placeholder="01_Script.sql", id=_iid(ct, idx, "script"))
            )
            widgets.append(
                Label("Base de datos (ej: RAWRAPSIIF):", classes="field-label")
            )
            widgets.append(
                Input(placeholder="RAWRAPSIIF", id=_iid(ct, idx, "bd"))
            )

        elif ct in (ComponentType.API_IIS, ComponentType.API_DOCKER):
            lbl = "servicio .zip" if ct == ComponentType.API_IIS else "servicio Docker"
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label(
                    f"Nombre del {lbl} (ej: WebRetailAuthentication):",
                    classes="field-label",
                )
            )
            widgets.append(
                Input(placeholder="WebRetailAuthentication", id=_iid(ct, idx, "nombre"))
            )
            # Sub-contenedor de configs
            cfg_container = Container(id=f"cfgs_{ct.value}_{idx}")
            widgets.append(cfg_container)
            widgets.append(
                Button(
                    "+ Agregar config (clave/valor)",
                    id=_add_cfg_btn_id(ct, idx),
                    classes="btn-add-cfg",
                )
            )

        elif ct == ComponentType.APIM:
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label("Nombre del servicio APIM:", classes="field-label")
            )
            widgets.append(
                Input(
                    placeholder="WebRetailAuthentication",
                    id=_iid(ct, idx, "nombre"),
                )
            )

        elif ct == ComponentType.LIFERAY:
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label(
                    "Nombre de la Remote App (ej: MXAuthentication):",
                    classes="field-label",
                )
            )
            widgets.append(
                Input(placeholder="MXAuthentication", id=_iid(ct, idx, "nombre"))
            )

        elif ct == ComponentType.BLOB:
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label("Nombre del archivo (ej: styles.css):", classes="field-label")
            )
            widgets.append(
                Input(placeholder="styles.css", id=_iid(ct, idx, "nombre"))
            )
            widgets.append(
                Label("Carpeta destino en Blob Storage:", classes="field-label")
            )
            widgets.append(
                Input(placeholder="assets/css", id=_iid(ct, idx, "carpeta"))
            )

        elif ct == ComponentType.ASSETS:
            widgets.append(
                Label(f"▸ {label_tipo} — instancia {idx + 1}", classes="inst-header")
            )
            widgets.append(
                Label("Nombre del archivo (ej: logo.png):", classes="field-label")
            )
            widgets.append(
                Input(placeholder="logo.png", id=_iid(ct, idx, "nombre"))
            )

        # Montar antes del botón "Agregar otro" (si ya existe)
        btn_add = type_container.query(f"#{_add_btn_id(ct)}")
        if btn_add:
            for w in widgets:
                await type_container.mount(w, before=btn_add.first())
        else:
            await type_container.mount(*widgets)

        if focus_new and widgets:
            # Dar foco al primer Input de la nueva instancia
            for w in widgets:
                if isinstance(w, Input):
                    w.focus()
                    break

    async def _mount_config_row(
        self, ct: ComponentType, inst_idx: int, *, focus_new: bool = False
    ) -> None:
        """Agrega un par clave/valor de config dentro de una instancia de API."""
        cfg_idx = self._state.add_config(ct, inst_idx)
        cfg_container = self.query_one(f"#cfgs_{ct.value}_{inst_idx}", Container)

        row = Horizontal(classes="cfg-row", id=f"cfgrow_{ct.value}_{inst_idx}_{cfg_idx}")
        inp_clave = Input(
            placeholder="Clave (ej: ConnectionStrings__Default)",
            id=_cfg_id(ct, inst_idx, cfg_idx, "clave"),
        )
        inp_valor = Input(
            placeholder="Valor",
            id=_cfg_id(ct, inst_idx, cfg_idx, "valor"),
        )
        await cfg_container.mount(row)
        await row.mount(inp_clave, inp_valor)

        if focus_new:
            inp_clave.focus()

    # ── Eventos de botones ────────────────────────────────────────────────────

    def on_button_pressed(self, event: Button.Pressed) -> None:
        btn_id = event.button.id or ""

        if btn_id == "btn-generate":
            self.action_generate()
            return
        if btn_id == "btn-back":
            self.action_go_back()
            return

        # Botón "Agregar instancia" de cualquier tipo
        for ct in _MULTI_INSTANCE:
            if btn_id == _add_btn_id(ct):
                type_container = self.query_one(f"#tc_{ct.value}", Container)
                self.run_worker(
                    self._mount_instance(ct, type_container, focus_new=True),
                    exclusive=False,
                )
                return

        # Botón "Agregar config" dentro de una instancia de API
        for ct in _HAS_CONFIGS:
            for inst_idx in range(self._state.instances(ct)):
                if btn_id == _add_cfg_btn_id(ct, inst_idx):
                    self.run_worker(
                        self._mount_config_row(ct, inst_idx, focus_new=True),
                        exclusive=False,
                    )
                    return

    def action_go_back(self) -> None:
        self.app.pop_screen()

    def _notify_error(self, msg: str) -> None:
        self.app.notify(msg, severity="error", timeout=6)
        self.query_one("#error-msg", Label).update(msg)

    # ── Generación ────────────────────────────────────────────────────────────

    def action_generate(self) -> None:
        """Valida, construye config, genera package."""
        success_label: Label = self.query_one("#success-msg", Label)
        self.query_one("#error-msg", Label).update("")
        success_label.styles.display = "none"

        ticket = self.query_one("#inp_ticket", Input).value.strip()
        hu_nombre = self.query_one("#inp_hu", Input).value.strip()
        iteracion = self.query_one("#inp_iteracion", Input).value.strip()
        ruta = self.query_one("#inp_ruta", Input).value.strip()

        sel_widget = self.query_one("#sel_ambiente", Select)
        ambiente: str = (
            str(sel_widget.value) if sel_widget.value is not Select.BLANK else "QA"
        )

        if not ticket:
            self._notify_error("El campo Ticket es obligatorio.")
            return
        if not iteracion:
            self._notify_error("El campo Iteracion es obligatorio.")
            return
        if not ruta:
            self._notify_error("La ruta de packages es obligatoria.")
            return
        if not Path(ruta).exists():
            self._notify_error(f"La ruta no existe: {ruta}")
            return

        selector: ComponentSelector = self.query_one("#comp_selector", ComponentSelector)
        tipos_seleccionados = selector.selected_components
        if not tipos_seleccionados:
            self._notify_error("Selecciona al menos un tipo de componente.")
            return

        componentes: list[ComponentConfig] = []
        for ct in tipos_seleccionados:
            tipo_display = TIPO_DISPLAY.get(ct, ct.value)
            comps = _read_all_instances(self, ct, tipo_display, ambiente)
            if comps is None:
                return  # _read_all_instances ya notificó
            componentes.extend(comps)

        config = PackageConfig(
            ticket=ticket,
            hu_nombre=hu_nombre,
            ambiente=ambiente,
            iteracion=iteracion,
            ruta_packages=ruta,
            componentes=componentes,
        )

        try:
            from portal_retail.services.doc_generator import generate_document
            from portal_retail.services.folder_service import (
                create_package_folders,
                save_package_meta,
            )

            package_dir = create_package_folders(config)
            doc_path = package_dir / "Manual" / f"{config.package_name}.docx"
            generate_document(config, doc_path)
            save_package_meta(config, package_dir)

            settings = SettingsManager()
            settings.load()
            settings.save_last_used({
                "ticket": ticket,
                "hu_nombre": hu_nombre,
                "ambiente": ambiente,
                "iteracion": iteracion,
                "ruta_packages": ruta,
            })

            result_msg = (
                f"Package generado: {config.package_name}\n"
                f"Carpeta: {package_dir}\n"
                f"Documento: {doc_path.name}"
            )
            self.app.notify(result_msg, severity="information", timeout=10)
            success_label.update(
                f"[OK] Package generado: {config.package_name}\n"
                f"  Carpeta  : {package_dir}\n"
                f"  Documento: {doc_path.name}"
            )
            success_label.styles.display = "block"
            self.query_one("#error-msg", Label).update("")
            self.query_one(VerticalScroll).scroll_end(animate=False)

        except Exception as exc:  # noqa: BLE001
            self._notify_error(f"Error al generar: {exc}")


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS: lectura del formulario
# ─────────────────────────────────────────────────────────────────────────────

def _inp(screen: PackageScreen, widget_id: str) -> str:
    """Lee el valor de un Input por ID, devuelve '' si no existe."""
    try:
        return screen.query_one(f"#{widget_id}", Input).value.strip()
    except Exception:  # noqa: BLE001
        return ""


def _read_all_instances(
    screen: PackageScreen,
    ct: ComponentType,
    tipo_display: str,
    ambiente: str,
) -> list[ComponentConfig] | None:
    """
    Lee todas las instancias de un tipo del formulario.
    Devuelve None si hay un campo obligatorio vacío (y notifica).
    """
    n = screen._state.instances(ct)
    if n == 0:
        return []

    label_tipo = COMPONENT_LABELS.get(ct, ct.value)
    result: list[ComponentConfig] = []

    for idx in range(n):
        comp = _read_one_instance(screen, ct, idx, tipo_display, ambiente, label_tipo)
        if comp is None:
            return None
        result.append(comp)

    return result


def _read_one_instance(
    screen: PackageScreen,
    ct: ComponentType,
    idx: int,
    tipo_display: str,
    ambiente: str,
    label_tipo: str,
) -> ComponentConfig | None:
    """Lee los campos de una instancia concreta. Devuelve None si hay error."""

    inst_label = f"[{label_tipo} #{idx + 1}]"

    if ct == ComponentType.LIFERAY_BUILD:
        build_id = _inp(screen, _iid(ct, idx, "build_id"))
        if not build_id:
            screen._notify_error(f"{inst_label} El Build ID es obligatorio.")
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=f"Build #{build_id}",
            tipo_display=tipo_display,
            contenedor=ambiente,
            build_id=build_id,
        )

    elif ct == ComponentType.SQL:
        script = _inp(screen, _iid(ct, idx, "script"))
        bd = _inp(screen, _iid(ct, idx, "bd"))
        if not script:
            screen._notify_error(f"{inst_label} El nombre del script es obligatorio.")
            return None
        if not bd:
            screen._notify_error(f"{inst_label} La base de datos es obligatoria.")
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=script,
            tipo_display=tipo_display,
            contenedor=ambiente,
            scripts=[script],
            base_datos=bd,
        )

    elif ct in (ComponentType.API_IIS, ComponentType.API_DOCKER):
        nombre = _inp(screen, _iid(ct, idx, "nombre"))
        if not nombre:
            screen._notify_error(f"{inst_label} El nombre del servicio es obligatorio.")
            return None
        configs = _read_configs(screen, ct, idx)
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=nombre,
            tipo_display=tipo_display,
            contenedor=ambiente,
            nombre_servicio=nombre,
            configs=configs,
        )

    elif ct == ComponentType.APIM:
        nombre = _inp(screen, _iid(ct, idx, "nombre"))
        if not nombre:
            screen._notify_error(f"{inst_label} El nombre del servicio APIM es obligatorio.")
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=nombre,
            tipo_display=tipo_display,
            contenedor=ambiente,
            nombre_servicio=nombre,
        )

    elif ct == ComponentType.LIFERAY:
        nombre = _inp(screen, _iid(ct, idx, "nombre"))
        if not nombre:
            screen._notify_error(
                f"{inst_label} El nombre de la Remote App es obligatorio."
            )
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=nombre,
            tipo_display=tipo_display,
            contenedor=ambiente,
            nombre=nombre,
            tipo="remote_app",
        )

    elif ct == ComponentType.BLOB:
        nombre = _inp(screen, _iid(ct, idx, "nombre"))
        carpeta = _inp(screen, _iid(ct, idx, "carpeta"))
        if not nombre:
            screen._notify_error(f"{inst_label} El nombre del archivo es obligatorio.")
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=nombre,
            tipo_display=tipo_display,
            contenedor=ambiente,
            archivos=[{"nombre": nombre, "carpeta": carpeta or nombre.rsplit(".", 1)[0]}],
        )

    elif ct == ComponentType.ASSETS:
        nombre = _inp(screen, _iid(ct, idx, "nombre"))
        if not nombre:
            screen._notify_error(f"{inst_label} El nombre del archivo es obligatorio.")
            return None
        return ComponentConfig(
            tipo_clave=ct,
            nombre_display=nombre,
            tipo_display=tipo_display,
            contenedor=ambiente,
            archivos=[{"nombre": nombre, "carpeta": ""}],
        )

    # Fallback
    return ComponentConfig(
        tipo_clave=ct,
        nombre_display=label_tipo,
        tipo_display=tipo_display,
        contenedor=ambiente,
    )


def _read_configs(
    screen: PackageScreen, ct: ComponentType, inst_idx: int
) -> list[dict[str, str]]:
    """Lee todos los pares clave/valor de configs de una instancia de API."""
    n = screen._state.configs(ct, inst_idx)
    configs = []
    for cfg_idx in range(n):
        clave = _inp(screen, _cfg_id(ct, inst_idx, cfg_idx, "clave"))
        valor = _inp(screen, _cfg_id(ct, inst_idx, cfg_idx, "valor"))
        if clave:  # solo incluir si tiene clave
            configs.append({"clave": clave, "valor": valor})
    return configs
