# mgg-packgen-v2

Generador de Packages de Instalación — TUI standalone con [Textual](https://textual.textualize.io/).

Reescritura de `package_generator.py` v1 (CLI) como aplicación TUI con formulario dinámico, soporte multi-componente y generación automática de manual `.docx`.

## Requisitos

- Python 3.12+
- Windows (o cualquier plataforma con soporte terminal ANSI)

## Instalación

```bash
# Clonar / descargar el repositorio
cd C:\Users\ito_mgg\source\repos\mgg-packgen-v2

# Crear entorno virtual
python -m venv .venv
.venv\Scripts\activate

# Instalar dependencias
pip install -e .

# Instalar dependencias de desarrollo (pytest, ruff)
pip install -e .[dev]
```

## Uso

```bash
# Iniciar la TUI
python -m portal_retail

# O con el entrypoint instalado
mgg-packgen
```

## Estructura del proyecto

```
mgg-packgen-v2/
├── pyproject.toml
├── src/
│   └── portal_retail/
│       ├── main.py             # Entrypoint + banner ASCII
│       ├── core/               # Dominio: ComponentType, ComponentConfig, PackageConfig
│       ├── services/           # doc_generator, folder_service, copy_service
│       ├── config/             # SettingsManager — persistencia JSON en APPDATA
│       └── tui/                # App Textual: screens + widgets
│           ├── app.py          # PortalRetailApp
│           ├── app.tcss        # Estilos globales
│           ├── screens/
│           │   ├── main_screen.py    # Menú principal
│           │   ├── package_screen.py # Formulario de creación (multi-instancia)
│           │   └── clone_screen.py   # Clonar package existente
│           └── widgets/
│               ├── component_selector.py  # SelectionList de 8 tipos
│               └── server_form.py         # (deprecado — ya no se usa en el form)
└── tests/
    ├── unit/
    │   ├── test_naming.py
    │   ├── test_doc_generator.py
    │   ├── test_folder_service.py
    │   └── test_settings.py
    └── integration/
        ├── test_full_generation.py
        └── test_clone_roundtrip.py
```

## Componentes soportados

| Tipo | Campos TUI | Instancias |
|------|-----------|------------|
| Liferay Build | Build ID | 1 (única) |
| SQL | Script + Base de datos | N |
| API IIS | Nombre servicio + N configs clave/valor | N |
| API Docker | Nombre servicio + N configs clave/valor | N |
| Azure API Management | Nombre servicio | N |
| Liferay Remote App | Nombre Remote App | N |
| Blob Storage | Nombre archivo + Carpeta | N |
| Assets (Liferay) | Nombre archivo | N |

## Desarrollo

```bash
# Lint
ruff check src/

# Tests
pytest tests/
```

## Configuración persistida

El último uso (ticket, HU, ambiente, iteración, ruta) se guarda automáticamente en:
- Windows: `%APPDATA%\portal_retail\config.json`
- Linux/Mac: `~/.config/portal_retail/config.json`

## Formato del package generado

```
{ticket}-PortalRetail_{AMBIENTE}-{iteracion zfill(2)}
```

Ejemplo: `MX01-274906-PortalRetail_QA-01`

Dentro del package se crea:
```
MX01-274906-PortalRetail_QA-01/
├── Componentes/
│   ├── API/
│   ├── SQL/
│   └── ...  (según tipos seleccionados)
├── Manual/
│   └── MX01-274906-PortalRetail_QA-01.docx
└── package_meta.json
```

## Renombrar directorio

El directorio físico aún puede llamarse `portal-retail-v2` si el proceso lo tiene bloqueado.
Para renombrarlo definitivamente:
1. Cerrar la TUI y desactivar el venv
2. `Rename-Item portal-retail-v2 mgg-packgen-v2`
