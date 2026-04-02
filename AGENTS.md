# AGENTS.md — mgg-packgen v3

Context file for AI agents and coding assistants.

## Project Overview

**mgg-packgen v3** — Portal Retail Skandia México  
Windows 11 desktop app that generates installation packages (.docx + folder structure).

Architecture: Flutter UI desktop app spawns a Python FastAPI process as a child.
Flutter communicates via HTTP REST to `localhost:8787`.

## Repository Layout

```
mgg-packgen-v3/
├── PROMPT_V3.md      ← ORIGINAL SPEC — source of truth (755 lines)
├── ARCHITECTURE.md   ← tech stack, patterns, domain rules
├── api/              ← Python FastAPI backend
│   ├── AGENTS.md     ← API-specific context
│   ├── pyproject.toml
│   └── src/mgg_packgen_api/
│       ├── main.py
│       ├── routes/   health.py, packages.py, settings.py
│       ├── schemas/  options.py, package.py, settings.py
│       └── services/ component.py, doc_generator.py, folder_service.py,
│                     options_service.py, package.py, settings_service.py
└── app/              ← Flutter Desktop app
    ├── AGENTS.md     ← Flutter-specific context
    ├── pubspec.yaml
    └── lib/
        ├── main.dart, app.dart
        ├── core/     api_client.dart, constants.dart, server_manager.dart
        ├── models/   (6 files)
        ├── providers/ (5 files)
        ├── screens/  (6 files)
        └── widgets/  (4 files)
```

## Critical Rules — READ BEFORE TOUCHING CODE

### Navigation (Flutter)
- **NEVER use `Navigator.pop()` or `context.pop()`**
- ALWAYS use `context.go('/route')` — go_router flat config, no stack
- Back buttons: `context.go('/home')` or the appropriate parent route

### State Management (Flutter)
- **NEVER use `AsyncNotifier.update()`** — it is a reserved Riverpod framework method
- User-triggered saves use a custom `save()` method on the notifier

### Python API
- **No virtualenv** — packages installed globally
- Run API: `cd api && python -m mgg_packgen_api.main`
- API port: **8787** (hardcoded, not user-configurable)
- Run tests: `cd api && python -m pytest` (61 tests)

### Flutter App
- Run: `cd app && flutter run -d windows`
- Run tests: `cd app && flutter test` (96 tests)
- **All tests must remain green after any change**

### DO NOT
- Modify anything in `mgg-packgen-v1` or `mgg-packgen-v2` repos
- Change the API port (8787) — hardcoded in both Flutter and API
- Use `Navigator.pop()` — will break navigation (flat router, no stack)
- Use `AsyncNotifier.update()` — reserved method

## Domain Rules

### 8 Component Types (canonical order)
```
liferay_build → sql → api_iis → api_docker → blob → liferay → assets → apim
```

### Componentes Afectados Table
| Type | NOMBRE | TIPO | CONTENEDOR | UBICACIÓN |
|------|--------|------|------------|-----------|
| `liferay_build` | `"#" + build_id` | `"BUILD"` | `"liferay"` | ambiente |
| `sql` | script name | `inst.tipo \|\| "SQL"` | `nombre_bd` | ambiente |
| `api_iis` | `nombre_servicio` | `"API"` | `"IIS"` | ambiente |
| `api_docker` | `nombre_servicio` | `"API"` | `"Docker"` | ambiente |
| `blob` | archivo name | `"Blob Storage"` | `"Azure Blob Storage"` | ambiente |
| `liferay` | `inst.nombre` | `"Liferay"` | `"Liferay"` | ambiente |
| `assets` | first archivo | `"Assets"` | `"Assets"` | ambiente |
| `apim` | `nombre_servicio` | `"API Management"` | `"APIM"` | ambiente |

### Expansion Rules
- `sql`: expands to **1 row per script** (not per instance)
- `blob`: expands to **1 row per archivo** (not per instance)
- `liferay_build`: max 1 instance; does **NOT** create a physical folder
- UBICACIÓN: always only `ambiente` (never `"{bd} | {ambiente}"`)

### Package Name Format
`{ticket}-PortalRetail_{AMBIENTE}-{iteracion.zfill(2)}`  
Example: `INC-1234-PortalRetail_QA-03`

### QA → UAT
In docx Liferay Build section ONLY:  
`ambiente_display = "UAT" if ambiente == "QA" else ambiente`

## Config Persistence

Files in `%APPDATA%\mgg_packgen_api\`:
- `config.json` — servers QA/PROD
- `options.json` — estatus list, SQL tipo list, Blob tipo list

## Test Commands

```bash
# API tests
cd api
python -m pytest

# Flutter tests
cd app
flutter test
```

## Key Files for Context

| File | What it does |
|------|-------------|
| `PROMPT_V3.md` | Original spec — authoritative for any domain rule question |
| `ARCHITECTURE.md` | Stack, patterns, data flow |
| `api/src/mgg_packgen_api/routes/packages.py` | `_derive_component_config()` — expansion logic |
| `api/src/mgg_packgen_api/services/doc_generator.py` | .docx generation (903 lines) |
| `api/src/mgg_packgen_api/services/component.py` | `ComponentType` enum + canonical order |
| `app/lib/app.dart` | go_router flat config |
| `app/lib/core/api_client.dart` | HTTP client + all API methods |
| `app/lib/core/server_manager.dart` | Python process spawn/kill logic |

## VS Code Debug Configs

`.vscode/launch.json` has 3 configs:
1. **API (Python)** — runs FastAPI on :8787
2. **Flutter (Windows)** — runs Flutter desktop app
3. **Compound** — runs both together
