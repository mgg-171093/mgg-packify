# Architecture — mgg-packgen v3

Portal Retail Skandia México — generador de packages de instalación.
Windows 11 desktop app: Flutter UI + Python FastAPI backend (proceso hijo).

---

## Tech Stack

### Flutter App (`app/`)

| Package | Version | Purpose |
|---------|---------|---------|
| Flutter | 3.41.2 | UI framework (Windows desktop) |
| Dart | 3.11.0 | Language |
| flutter_riverpod | ^2.5.0 | State management |
| go_router | ^14.0.0 | Navigation (flat config) |
| http | ^1.2.0 | REST client |
| file_picker | ^8.0.0 | Folder/file picker dialogs |
| url_launcher | ^6.3.0 | Open folders in Explorer |
| google_fonts | ^6.2.0 | Typography |

### Python API (`api/`)

| Package | Version | Purpose |
|---------|---------|---------|
| Python | ≥3.12 | Language |
| fastapi | ≥0.110 | REST framework |
| uvicorn[standard] | ≥0.29 | ASGI server |
| python-docx | ≥1.0 | .docx generation |
| platformdirs | ≥4.0 | Config path (`%APPDATA%\mgg_packgen_api\`) |
| pydantic | ≥2.0 | Schema validation |
| ruff | ≥0.4 | Linter/formatter |
| pytest | ≥8.0 | Tests |
| httpx | ≥0.27 | Test HTTP client |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Windows 11 Desktop                                     │
│                                                         │
│  ┌─────────────────────┐     HTTP REST      ┌────────┐  │
│  │   Flutter App       │ ◄──────────────► │  API   │  │
│  │  (app/lib/)         │  localhost:8787   │(child) │  │
│  │                     │                  │        │  │
│  │  Riverpod Providers │    Spawns on      │FastAPI │  │
│  │  go_router (flat)   │ ───────────────► │uvicorn │  │
│  │  ApiClient (http)   │     startup       │:8787   │  │
│  └─────────────────────┘                  └───┬────┘  │
│                                               │        │
│                                     ┌─────────▼──────┐ │
│                                     │  %APPDATA%\    │ │
│                                     │  mgg_packgen_  │ │
│                                     │  api\          │ │
│                                     │  config.json   │ │
│                                     │  options.json  │ │
│                                     └────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Process Management

`ServerManager` (`app/lib/core/server_manager.dart`) manages the API child process:

- **Release mode**: launches `mgg-packgen-api.exe` from the same directory as the Flutter exe
- **Dev mode**: checks if port 8787 is already listening; if yes, skips launch (lets you run API from VS Code/terminal manually). If no, launches `python -m mgg_packgen_api.main` from `api/` directory.
- **Shutdown**: kills child process on `AppLifecycleState.detached`
- **DEV_PATH override**: `MGG_API_PATH` environment variable overrides the API path resolution

### HTTP Client

`ApiClient` (`app/lib/core/api_client.dart`):
- Base URL: `http://127.0.0.1:8787` — hardcoded, no user-configurable host
- Timeout: 30 seconds per request
- Error handling: all errors wrapped in `ApiException(message, statusCode)`
- Injected via Riverpod `Provider<ApiClient>` with `ref.onDispose(client.dispose)`

---

## Navigation — go_router Flat Config

All routes are flat (no nesting). **NEVER use `Navigator.pop()` or `context.pop()`.**
Always navigate with `context.go('/route')`.

```
/splash  →  /home  →  /new-package  →  /success
                  →  /clone
                  →  /settings
```

| Route | Screen | Notes |
|-------|--------|-------|
| `/splash` | `SplashScreen` | Waits for API health check, then goes to `/home` |
| `/home` | `HomeScreen` | Package list, entry point for all actions |
| `/new-package` | `NewPackageScreen` | Form to create a new package |
| `/success` | `SuccessScreen` | Shows result; requires `state.extra as GenerateResult` |
| `/clone` | `CloneScreen` | Pre-fill form from existing package |
| `/settings` | `SettingsScreen` | Servers + Options tabs |

---

## State Management — Riverpod

All providers use the `AsyncNotifier<T>` pattern.

### Critical Rule: `update()` is reserved by Riverpod

Do NOT use `AsyncNotifier.update()` — it is a framework method. All notifiers expose a **`save()`** method for user-triggered persistence.

### Provider Pattern

```dart
class SettingsNotifier extends AsyncNotifier<SettingsModel> {
  @override
  Future<SettingsModel> build() async {
    // Load from API on init
    return await ref.read(apiClientProvider).getSettings();
  }

  // User-triggered save — NOT update()
  Future<void> save(SettingsModel settings) async {
    state = const AsyncLoading();
    try {
      await ref.read(apiClientProvider).putSettings(settings);
      state = AsyncData(settings);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);
```

### Providers

| Provider | Type | State |
|----------|------|-------|
| `apiClientProvider` | `Provider<ApiClient>` | HTTP client singleton |
| `serverManagerProvider` | `Provider<ServerManager>` | Process manager (overridden in main) |
| `settingsProvider` | `AsyncNotifierProvider<SettingsNotifier, SettingsModel>` | Server config |
| `optionsProvider` | `AsyncNotifierProvider<OptionsNotifier, OptionsModel>` | Estatus/tipo lists |
| `packageFormProvider` | `AsyncNotifierProvider<...>` | New package form state |
| `serverStatusProvider` | `AsyncNotifierProvider<...>` | API health status |
| `cloneListProvider` | `AsyncNotifierProvider<...>` | Package list for clone screen |

---

## Domain Model — Component Types

8 types in canonical order (also the docx rendering order):

```
liferay_build → sql → api_iis → api_docker → blob → liferay → assets → apim
```

### Expansion Rules (Flutter → API)

Flutter sends `{ tipo, instancias: [InstanceIn] }`. The API expands each instance:

| Type | Expansion | NOMBRE | TIPO | CONTENEDOR |
|------|-----------|--------|------|------------|
| `liferay_build` | 1 row/instance | `"#" + build_id` | `"BUILD"` | `"liferay"` |
| `sql` | **1 row/script** | script name | `inst.tipo \|\| "SQL"` | `nombre_bd` |
| `api_iis` | 1 row/instance | `nombre_servicio` | `"API"` | `"IIS"` |
| `api_docker` | 1 row/instance | `nombre_servicio` | `"API"` | `"Docker"` |
| `blob` | **1 row/archivo** | archivo name | `"Blob Storage"` | `"Azure Blob Storage"` |
| `liferay` | 1 row/instance | `inst.nombre` | `"Liferay"` | `"Liferay"` |
| `assets` | 1 row/instance | first archivo name | `"Assets"` | `"Assets"` |
| `apim` | 1 row/instance | `nombre_servicio` | `"API Management"` | `"APIM"` |

### Special Rules

- **`liferay_build`**: single-instance only (UI enforces max 1). Does NOT create a physical folder.
- **UBICACIÓN column**: always `ambiente` only (never includes base_datos).
- **QA → UAT**: in the docx Liferay Build section only — `ambiente_display = "UAT" if ambiente == "QA" else ambiente`.

---

## Package Name Format

```
{ticket}-PortalRetail_{AMBIENTE}-{iteracion.zfill(2)}
```

Example: `INC-1234-PortalRetail_QA-03`

- `AMBIENTE` is always uppercase (normalized in the API)
- `iteracion` is zero-padded to 2 digits

---

## Config Persistence

Files stored via `platformdirs` in `%APPDATA%\mgg_packgen_api\`:

| File | Contents | Endpoint |
|------|----------|----------|
| `config.json` | Servers QA/PROD + `last_used` flag | `GET/PUT /settings` |
| `options.json` | Estatus list, SQL tipo list, Blob tipo list | `GET/PUT /settings/options` |

---

## .docx Generation Pipeline

```
POST /packages/generate
  │
  ├── Validate ruta_packages exists
  ├── _derive_component_config() — expand instances → ComponentConfig list
  ├── Sort by canonical order
  ├── create_package_folders() — mkdir structure
  ├── generate_document() — python-docx → .docx
  │     ├── add_footer() — XML direct (tabs at 4419/8838 EMU)
  │     ├── build_components_table() — gridSpan + XML cell merges
  │     └── gen_seccion_* per component type
  └── save_package_meta() — package_meta.json in package root
```

### Style Constants (doc_generator.py)

| Constant | Value | Usage |
|----------|-------|-------|
| `COLOR_VERDE_HEADER` | `#70AD47` | Table header row |
| `COLOR_VERDE_BORDES` | `#C5E0B3` | Table borders |
| `COLOR_VERDE_GRUPO` | `#E2EFD9` | Group separator rows |
| `AUTOR_FOOTER` | `"Manuel García González"` | Footer hardcoded |
| `FUENTE_DEFAULT` | `"Calibri"` | Body font |

---

## Folder Structure

```
D:\Drive\Personal\repos\mgg-packgen-v3\
├── PROMPT_V3.md               ← original spec (755 lines, source of truth)
├── ARCHITECTURE.md            ← this file
├── AGENTS.md                  ← AI agent context
├── .vscode/
│   └── launch.json            ← 3 configs: API, Flutter, compound
├── api/                       ← Python FastAPI backend
│   ├── AGENTS.md
│   ├── pyproject.toml
│   └── src/mgg_packgen_api/
│       ├── main.py
│       ├── routes/            health.py, packages.py, settings.py
│       ├── schemas/           options.py, package.py, settings.py
│       └── services/          component.py, doc_generator.py, folder_service.py,
│                              options_service.py, package.py, settings_service.py
└── app/                       ← Flutter Desktop app
    ├── AGENTS.md
    ├── pubspec.yaml
    └── lib/
        ├── main.dart          ← entry point + lifecycle
        ├── app.dart           ← go_router config + ThemeData
        ├── core/              api_client.dart, constants.dart, server_manager.dart
        ├── models/            component_config, generate_result, options_model,
        │                      package_config, package_list_item, settings_model
        ├── providers/         clone_list, options, package_form,
        │                      server_status, settings
        ├── screens/           clone, home, new_package, settings,
        │                      splash, success
        └── widgets/           component_detail_card, component_selector,
                               package_name_preview, server_form
```

---

## Brand Colors

| Name | Hex | Usage |
|------|-----|-------|
| `kGreenPrimary` | `#70AD47` | Primary theme seed + docx headers |
| `kGreenLight` | `#C5E0B3` | Table borders |
| `kGreenVeryLight` | `#E2EFD9` | Table group separators |
| `kBlue` | `#4472C4` | Secondary accent |

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check (used by SplashScreen polling) |
| `GET` | `/settings` | Get server config |
| `PUT` | `/settings` | Save server config |
| `GET` | `/settings/options` | Get estatus/tipo option lists |
| `PUT` | `/settings/options` | Save option lists |
| `POST` | `/packages/generate` | Generate package (folders + docx) |
| `POST` | `/packages/clone` | Load existing package meta for pre-fill |
| `GET` | `/packages/list?base_dir=` | List packages in directory |

---

## Test Coverage

| Suite | Count | Command |
|-------|-------|---------|
| pytest (API) | 61 tests | `cd api && python -m pytest` |
| flutter test | 96 tests | `cd app && flutter test` |

All tests must remain green after any change.
