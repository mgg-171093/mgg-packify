# AGENTS.md — API (Python FastAPI)

Context for AI agents working on the Python backend of mgg-packgen v3.

## Overview

FastAPI backend that runs as a child process of the Flutter desktop app.  
Serves on `localhost:8787`. Generates .docx installation packages.

## Running

```bash
# From repo root
cd api
python -m mgg_packgen_api.main

# Or as installed script
mgg-packgen-api
```

**No virtualenv** — packages are installed globally.  
If `import mgg_packgen_api` fails, run: `pip install -e api/`

## Testing

```bash
cd api
python -m pytest              # all 61 tests
python -m pytest -v           # verbose
python -m pytest tests/test_packages_derive.py  # single file
```

All tests must pass after any change.

## Package Layout

```
api/
├── pyproject.toml
└── src/mgg_packgen_api/
    ├── main.py               ← FastAPI app + uvicorn entry point
    ├── routes/
    │   ├── health.py         ← GET /health
    │   ├── packages.py       ← POST /packages/generate, /clone, GET /list
    │   └── settings.py       ← GET/PUT /settings, /settings/options
    ├── schemas/
    │   ├── package.py        ← GenerateRequest/Response, ComponentIn, InstanceIn, etc.
    │   ├── settings.py       ← ServerConfig, SettingsOut
    │   └── options.py        ← OptionsOut schema
    └── services/
        ├── component.py      ← ComponentType enum, ComponentConfig dataclass
        ├── doc_generator.py  ← .docx generation (903 lines)
        ├── folder_service.py ← mkdir structure, package_meta.json
        ├── options_service.py← load/save options.json
        ├── package.py        ← PackageConfig dataclass, package_name property
        └── settings_service.py ← load/save config.json
```

## Endpoints

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| `GET` | `/health` | `health.py` | Liveness check |
| `GET` | `/settings` | `settings.py` | Get server config |
| `PUT` | `/settings` | `settings.py` | Save server config |
| `GET` | `/settings/options` | `settings.py` | Get option lists |
| `PUT` | `/settings/options` | `settings.py` | Save option lists |
| `POST` | `/packages/generate` | `packages.py` | Generate package (full) |
| `POST` | `/packages/clone` | `packages.py` | Load meta for pre-fill |
| `GET` | `/packages/list` | `packages.py` | List packages in dir |

## Key Logic

### `_derive_component_config()` — `routes/packages.py`

The core expansion function. Converts `(ComponentIn, InstanceIn)` → `list[ComponentConfig]`:

- `sql`: 1 `ComponentConfig` **per script** in `inst.scripts`
- `blob`: 1 `ComponentConfig` **per archivo** in `inst.archivos`
- all others: 1 `ComponentConfig` per instance

Canonical order is then applied via `_CANONICAL_ORDER` list sort before building `PackageConfig`.

### `generate_document()` — `services/doc_generator.py`

Generates the .docx. Critical fidelity rules (ported 1:1 from v1):
- `add_footer()`: uses raw XML with tab stops at 4419/8838 EMU — do NOT rewrite this
- `build_components_table()`: uses gridSpan + XML for cell merges — do NOT rewrite this
- QA → UAT substitution: **only** in `gen_seccion_liferay_build()`
- Author footer: hardcoded `"Manuel García González"`
- Colors: header `#70AD47`, borders `#C5E0B3`, group separator `#E2EFD9`

### Config Persistence — `services/settings_service.py` + `options_service.py`

Persists to `%APPDATA%\mgg_packgen_api\` via `platformdirs.user_data_dir()`:
- `config.json` — `{"qa": {...}, "prod": {...}, "last_used": "qa"|"prod"}`
- `options.json` — `{"estatus": [...], "sql_tipo": [...], "blob_tipo": [...]}`

## Data Flow for Package Generation

```
POST /packages/generate
  ├── req: GenerateRequest (Pydantic schema from Flutter)
  ├── _derive_component_config(comp, inst) for each (component, instance)
  │     └── Returns list[ComponentConfig] (expanded)
  ├── sorted by _CANONICAL_ORDER
  ├── PackageConfig built
  ├── create_package_folders(config) → package_dir Path
  ├── generate_document(config, doc_path) → writes .docx
  └── save_package_meta(config, package_dir) → writes package_meta.json
```

## Domain Rules — Quick Reference

```python
# Canonical component order
COMPONENT_ORDER = [
    "liferay_build", "sql", "api_iis", "api_docker",
    "blob", "liferay", "assets", "apim"
]

# ComponentType is a StrEnum
class ComponentType(StrEnum):
    LIFERAY_BUILD = "liferay_build"
    SQL = "sql"
    ...

# liferay_build does NOT create a physical folder (special case in folder_service.py)
# sql/blob expand to N rows; others expand to 1 row per instance
# QA → UAT ONLY in gen_seccion_liferay_build()
```

## Test Structure

```
api/tests/
├── conftest.py               ← TestClient fixtures
├── test_health.py            ← /health endpoint
├── test_settings.py          ← /settings CRUD
├── test_options.py           ← /settings/options CRUD
├── test_packages_generate.py ← POST /packages/generate (integration)
├── test_packages_clone.py    ← POST /packages/clone
├── test_packages_list.py     ← GET /packages/list
├── test_packages_derive.py   ← _derive_component_config() unit tests
├── test_doc_generator.py     ← doc generation smoke tests
└── test_schemas.py           ← Pydantic schema validation
```

## Gotchas

- LSP shows import errors in test files — these are **false positives** (PYTHONPATH not configured in LSP). Tests run fine with `python -m pytest`.
- `folder_service.py` line 144 has a Pyright type error — pre-existing, not a runtime issue.
- `liferay_build` NEVER creates a physical folder (checked in `folder_service.py` with a guard).
- UBICACIÓN column: always `ambiente` only — never concatenate with `base_datos`.
