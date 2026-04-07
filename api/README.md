# MGG-Packify API

FastAPI backend for **MGG-Packify — Portal Retail Skandia México**.  
Runs as a child process spawned by the Flutter app. Serves on `localhost:8787` and generates `.docx` installation packages.

→ See [root AGENTS.md](../AGENTS.md) for domain rules and critical context.  
→ See [api/AGENTS.md](./AGENTS.md) for AI-agent context (endpoint examples, schemas, gotchas).

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Python | ≥ 3.12 |
| OS | Windows 11 (primary target) |

**No virtualenv** — packages are installed globally. This is intentional and must not change.

---

## Install

```bash
# From repo root
pip install -e api/
```

This installs the package in editable mode with all runtime dependencies:
`fastapi`, `uvicorn`, `python-docx`, `platformdirs`, `pydantic`.

To install dev dependencies (pytest, httpx, ruff):

```bash
pip install -e "api/[dev]"
```

---

## Run

```bash
cd api
python -m mgg_packify_api.main
```

The API starts on `http://localhost:8787`. The Flutter app also accepts an
`MGG_API_PATH` environment variable to override the path resolution.

---

## Test

```bash
cd api
python -m pytest          # run all 87 tests
python -m pytest -v       # verbose output
python -m pytest tests/test_packages_derive.py  # single file
```

All tests must remain green after any change.

---

## Lint & Format

```bash
cd api
ruff check .              # lint check
ruff format .             # auto-format
ruff check . --fix        # lint + auto-fix
```

Line length: 100 chars (configured in `pyproject.toml`).

---

## Endpoint Reference

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness check — returns `{"status": "ok", "version": "3.0.0"}` |
| `GET` | `/settings` | Get server config (QA/PROD hosts) + last-used form values |
| `PUT` | `/settings` | Save server config and last-used values |
| `GET` | `/settings/options` | Get configurable option lists (estatus, SQL tipo, Blob tipo, etc.) |
| `PUT` | `/settings/options` | Save option lists |
| `POST` | `/packages/generate` | Generate full package: folders + `.docx` + optional publish |
| `POST` | `/packages/clone` | Load `package_meta.json` for pre-fill on clone |
| `GET` | `/packages/list` | List all packages in a directory, sorted by creation date desc |

Full endpoint documentation with JSON request/response examples: see [api/AGENTS.md](./AGENTS.md).

---

## Config File Paths

The API persists configuration to Windows AppData:

| File | Path | Contents |
|------|------|----------|
| `config.json` | `%APPDATA%\mgg_packify_api\config.json` | Server hostnames for QA and PROD environments; last-used form values |
| `options.json` | `%APPDATA%\mgg_packify_api\options.json` | Configurable lists: estatus, SQL tipo, Blob tipo, API services, SQL databases |

These files are created automatically with defaults on first run if they don't exist.

---

## ⚠️ Critical Do-Not-Touch Notes

### Port 8787

The API port is **hardcoded to 8787** in both this backend and the Flutter app. Do **not** change it.

```python
# api/src/mgg_packify_api/main.py
uvicorn.run(app, host="127.0.0.1", port=8787)
```

### No Virtualenv

Packages are installed globally by design. The Flutter app spawns `python -m mgg_packify_api.main`
directly — there is no virtualenv activation step. Do not introduce one.

### doc_generator.py — XML Sections

Two functions in `services/doc_generator.py` use raw XML and **must not be rewritten**:

- **`add_footer()`** — uses raw XML with tab stops at 4419/8838 EMU. Rewriting breaks footer alignment.
- **`build_components_table()`** — uses `gridSpan` + XML for cell merges. Rewriting breaks table layout.

The author footer constant is also hardcoded:

```python
AUTOR_FOOTER = "Manuel García González"
```

Do not change this value.

---

## Package Layout

```text
api/
├── pyproject.toml                        ← project metadata, dependencies, ruff config
└── src/mgg_packify_api/
    ├── main.py                           ← FastAPI app + uvicorn entry point
    ├── routes/
    │   ├── health.py                     ← GET /health
    │   ├── packages.py                   ← POST /packages/generate, /clone, GET /list
    │   └── settings.py                   ← GET/PUT /settings, /settings/options
    ├── schemas/
    │   ├── package.py                    ← GenerateRequest/Response, ComponentIn, etc.
    │   ├── settings.py                   ← ServerConfig, SettingsOut schemas
    │   └── options.py                    ← OptionsOut schema
    └── services/
        ├── component.py                  ← ComponentType enum + ComponentConfig dataclass
        ├── doc_generator.py              ← .docx generation (903 lines) — see warnings above
        ├── folder_service.py             ← mkdir structure, package_meta.json
        ├── options_service.py            ← load/save options.json
        ├── package.py                    ← PackageConfig dataclass, package_name property
        ├── publish_service.py            ← IIS publish pipeline (api_iis publicar=True)
        └── settings_service.py           ← load/save config.json
```

---

*Part of [MGG-Packify](../README.md) — Portal Retail Skandia México*
