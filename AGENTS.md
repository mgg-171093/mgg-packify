# AGENTS.md — MGG-Packify

Context file for AI agents and coding assistants working on MGG-Packify.

See also: [ARCHITECTURE.md](./ARCHITECTURE.md) · [api/AGENTS.md](./api/AGENTS.md) · [app/AGENTS.md](./app/AGENTS.md)

---

## Critical Rules — READ BEFORE TOUCHING CODE

### Navigation (Flutter)

| Rule | Correct | WRONG |
|------|---------|-------|
| Route navigation | `context.go('/route')` | `Navigator.pop(context)` / `context.pop()` |
| Back buttons | `context.go('/home')` | `context.pop()` — crashes flat router |
| Dialog close | `Navigator.of(ctx).pop()` inside dialog builder ✅ | N/A — this is the ONLY valid Navigator use |

> **Dialog exception**: `Navigator.of(ctx).pop()` is correct inside `AlertDialog` / `showDialog` builders. It closes the dialog overlay, not the route. This does NOT violate the `context.go()` rule.

### State Management (Flutter)

- **NEVER use `AsyncNotifier.update()`** — reserved Riverpod framework method; causes silent errors
- User-triggered saves use a custom `save()` method on each `AsyncNotifier` subclass

### Python API

- **No virtualenv** — packages installed globally
- Run API: `cd api && python -m mgg_packify_api.main`
- API port: **8787** (hardcoded in both Flutter and Python — do NOT change)
- Run tests: `cd api && python -m pytest`

### Flutter App

- Run: `cd app && flutter run -d windows`
- Run tests: `cd app && flutter test`
- **All tests must remain green after any change**

### DO NOT

- Modify anything in `mgg-packgen-v1` or `mgg-packgen-v2` repos
- Change the API port (8787) — hardcoded in both Flutter and API
- Use `Navigator.pop()` — will break navigation (flat router, no stack)
- Use `AsyncNotifier.update()` — reserved Riverpod method
- Reference brand colors (`kGreenPrimary`, etc.) — they were removed; theme uses `Colors.blue` seed

---

## Project Overview

**MGG-Packify** — Portal Retail Skandia México  
Windows 11 desktop app that generates installation packages (.docx + folder structure).

**Architecture**: Flutter desktop UI spawns a Python FastAPI process as a child. Flutter communicates via HTTP REST to `localhost:8787`.

---

## Repository Layout

```text
mgg-packify/
├── PROMPT_V3.md          ← ORIGINAL SPEC — source of truth (755 lines)
├── ARCHITECTURE.md       ← system diagrams, data flow, domain model
├── AGENTS.md             ← this file: critical rules, domain quick-ref, file map
├── README.md             ← human-facing: quick start, badges, tech stack
├── api/                  ← Python FastAPI backend
│   ├── AGENTS.md         ← API endpoints, JSON examples, Python gotchas
│   ├── README.md         ← API install/run/test for humans
│   ├── pyproject.toml
│   └── src/mgg_packify_api/
│       ├── main.py
│       ├── routes/       health.py, packages.py, settings.py
│       ├── schemas/      options.py, package.py, settings.py
│       └── services/     component.py, doc_generator.py, folder_service.py,
│                         options_service.py, package.py, publish_service.py,
│                         settings_service.py
└── app/                  ← Flutter Desktop app
    ├── AGENTS.md         ← screens, providers, widgets, navigation, Dart gotchas
    ├── README.md         ← Flutter run/test for humans
    ├── pubspec.yaml
    └── lib/
        ├── main.dart, app.dart
        ├── core/         api_client.dart, constants.dart, server_manager.dart
        ├── models/       (8 files — see Models section)
        ├── providers/    (10 files — see Providers section)
        ├── screens/      (9 files — see Screens section)
        └── widgets/      (5 files — see Widgets section)
```

---

## Route Table

| Route | Screen | `state.extra` | Back target | Transition |
|-------|--------|---------------|-------------|------------|
| `/splash` | `SplashScreen` | — | — | Fade 250ms |
| `/home` | `HomeScreen` | — | — | Fade 250ms |
| `/new-package` | `NewPackageScreen` | — | `/home` | Slide right 300ms |
| `/success` | `SuccessScreen` | `GenerateResult` (**required**) | `/home` | Slide right 300ms |
| `/clone` | `CloneScreen` | — | `/home` | Slide right 300ms |
| `/settings` | `SettingsScreen` | — | `/home` | Slide right 300ms |
| `/history` | `HistoryScreen` | — | `/home` | Slide right 300ms |
| `/logs` | `LogViewerScreen` | — | `/home` | Slide right 300ms |
| `/about` | `AboutScreen` | — | `/home` | Slide right 300ms |

---

## Screens (9 total)

| Screen | File | Description |
|--------|------|-------------|
| `SplashScreen` | `splash_screen.dart` | Starts Python server, polls `/health`, navigates to `/home` on success |
| `HomeScreen` | `home_screen.dart` | Landing: action buttons, template quick-apply list |
| `NewPackageScreen` | `new_package_screen.dart` | Main form: ticket, HU, ambiente, iteracion, components, generate |
| `SuccessScreen` | `success_screen.dart` | Shows result: package name, output path, open-folder button |
| `CloneScreen` | `clone_screen.dart` | Clone an existing package with a new iteration number |
| `SettingsScreen` | `settings_screen.dart` | 5-tab configuration (see Settings Tabs) |
| `HistoryScreen` | `history_screen.dart` | Last 50 generated packages — swipe to delete, tap to re-generate |
| `LogViewerScreen` | `log_viewer_screen.dart` | Two-tab log viewer (App / API logs) — reads `GET /logs` |
| `AboutScreen` | `about_screen.dart` | App info: versions, GitHub link, update check button |

### Settings Tabs (5)

| # | Tab | Content | Save behavior |
|---|-----|---------|---------------|
| 0 | Servidores QA | 4 server fields (API, BD, Blob, Liferay) for QA env | Manual save button |
| 1 | Servidores PROD | 4 server fields for PROD env | Manual save button |
| 2 | Opciones | Estatus list, SQL tipo list, Blob tipo list editor | Auto-save on change |
| 3 | Servicios API | `api_iis_services`, `api_docker_services`, `sql_databases` lists | Auto-save on change |
| 4 | Apariencia | Dark / Light / System theme toggle | Auto-save on change |

---

## Providers (10 total)

| Provider | File | Riverpod type | Persistence | Key methods |
|----------|------|---------------|-------------|-------------|
| `packageFormProvider` | `package_form_provider.dart` | `NotifierProvider<PackageFormNotifier, PackageFormState>` | In-memory only | `updateTicket`, `toggleComponent`, `addInstance`, `removeInstance`, `updateInstance`, `prefill`, `prefillFromHistory`, `applyTemplate`, `reset` |
| `settingsProvider` | `settings_provider.dart` | `AsyncNotifierProvider<SettingsNotifier, SettingsModel>` | API → `%APPDATA%\mgg_packify_api\config.json` | `save(settings)`, `clear()` |
| `optionsProvider` | `options_provider.dart` | `AsyncNotifierProvider<OptionsNotifier, OptionsModel>` | API → `%APPDATA%\mgg_packify_api\options.json` | `save(options)` |
| `historyProvider` | `history_provider.dart` | `AsyncNotifierProvider<HistoryNotifier, List<PackageHistoryEntry>>` | SharedPreferences key: `history_entries` (cap 50) | `add(entry)`, `delete(index)`, `clear()` |
| `templatesProvider` | `templates_provider.dart` | `AsyncNotifierProvider<TemplatesNotifier, List<PackageTemplate>>` | SharedPreferences key: `templates_list` | `save(template)`, `delete(index)` |
| `themeModeProvider` | `theme_mode_provider.dart` | `AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>` | SharedPreferences key: `theme_mode` | `setMode(mode)`, `toggle()` |
| `serverStatusProvider` | `server_status_provider.dart` | `StateProvider<ServerStatus>` | In-memory only | Set via `.notifier.state = ...` |
| `cloneListProvider` | `clone_list_provider.dart` | `FutureProvider.family<List<PackageListItem>, String>` | No persistence (API call) | Parameterized by `baseDir` string |
| `healthPollingProvider` | `health_polling_provider.dart` | `NotifierProvider<HealthPollingNotifier, void>` | In-memory only | `startPolling()`, `stopPolling()` |
| `updateCheckProvider` | `update_check_provider.dart` | `AsyncNotifierProvider<UpdateCheckNotifier, UpdateCheckState>` | In-memory only | `checkForUpdates()` |

### Critical Provider Gotchas

- **`packageFormProvider` is `Notifier` (sync), NOT `AsyncNotifier`** — `build()` returns state directly, no async
- **`cloneListProvider` is `FutureProvider.family`** — must pass `baseDir`: `ref.watch(cloneListProvider(baseDir))`
- **`serverStatusProvider` is `StateProvider`** — mutate directly: `ref.read(serverStatusProvider.notifier).state = ServerStatus.ready`
- **`AsyncNotifier.update()` is FORBIDDEN** — all `AsyncNotifier` subclasses use custom `save()` methods
- **`historyProvider.add()`** prepends entries and caps at 50; older entries beyond cap are dropped

---

## Models (8 total)

| Model | File | Description |
|-------|------|-------------|
| `ComponentConfig` | `component_config.dart` | `ComponentType` enum (8 types), `ComponentInstanceState`, `kCanonicalComponentOrder`, `ServerConfig` |
| `PackageConfig` | `package_config.dart` | Form data for the generate API request; serializes to JSON |
| `SettingsModel` | `settings_model.dart` | Server config (QA/PROD) with `ServerEnvironment` nested model |
| `GenerateResult` | `generate_result.dart` | API response: `packageName`, `packageDir`, `docxPath`, `success`, `error` |
| `OptionsModel` | `options_model.dart` | Lists: `estatusList`, `tipoSqlList`, `tipoBlobList`, `apiIisServices`, `apiDockerServices`, `sqlDatabases` |
| `PackageHistoryEntry` | `package_history_entry.dart` | History record: `packageName`, `ticket`, `huNombre`, `ambiente`, `iteracion`, `packageDir`, `generatedAt` |
| `PackageTemplate` | `package_template.dart` | Template: `name`, `selectedTypes` (as `List<String>`); instances NOT persisted |
| `PackageListItem` | `package_list_item.dart` | Clone screen list item: `name`, `path` |

---

## Widgets (5 total)

| Widget | File | Type | Description |
|--------|------|------|-------------|
| `ComponentDetailCard` | `component_detail_card.dart` | `StatefulWidget` | Per-type form fields with collapsible card, instance management, `AnimationController` |
| `ComponentSelector` | `component_selector.dart` | `StatelessWidget` | `Wrap` of `FilterChip` for selecting component types in canonical order |
| `PackageNamePreview` | `package_name_preview.dart` | `StatelessWidget` | Live preview formula + copy to clipboard button |
| `GenerationProgressDialog` | `generation_progress_dialog.dart` | `StatefulWidget` | Modal with optimistic 4-step progress, `Timer.periodic(600ms)`, 300ms delay on done |
| `ServerForm` | `server_form.dart` | `StatefulWidget` | Server URL fields shown conditionally by selected component types |

---

## Domain Rules

### 8 Component Types (canonical order)

```text
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

```text
{ticket}-PortalRetail_{AMBIENTE}-{iteracion.zfill(2)}
```

Example: `INC-1234-PortalRetail_QA-03`

### QA → UAT Display

In .docx Liferay Build section ONLY:

```python
ambiente_display = "UAT" if ambiente == "QA" else ambiente
```

---

## Config Persistence

### API-Side (Python — `%APPDATA%\mgg_packify_api\`)

| File | Content |
|------|---------|
| `config.json` | Server URLs: QA and PROD environments (API, BD, Blob, Liferay) |
| `options.json` | Estatus list, SQL tipo list, Blob tipo list, service lists |

### Flutter-Side (SharedPreferences)

| Key | Provider | Content |
|-----|----------|---------|
| `history_entries` | `historyProvider` | Last 50 generated packages (JSON list, capped) |
| `templates_list` | `templatesProvider` | Saved templates (name + selectedTypes; instances not saved) |
| `theme_mode` | `themeModeProvider` | Dark / Light / System preference |

---

## Beyond-Spec Features

These features exist in the codebase but were **NOT** in the original `PROMPT_V3.md` spec:

| Feature | Where | Description |
|---------|-------|-------------|
| **History** | `HistoryScreen` + `historyProvider` | Stores last 50 generated packages in SharedPreferences; swipe-to-delete; tap to re-generate |
| **Templates** | `HomeScreen` + `templatesProvider` | Save named templates (component types only, not instances); quick-apply from home |
| **Dark mode** | `SettingsScreen` (Apariencia tab) + `themeModeProvider` | System / Light / Dark toggle persisted in SharedPreferences |
| **Publish pipeline** | `publish_service.py` | IIS service publish triggered when `publicar=True` on `api_iis` instances; has its own test file |
| **Image injection** | `doc_generator.py` | `ConfigItemIn.imagen_path` — embeds custom image into .docx document |
| **Toast notifications** | `local_notifier` package | Windows native toast shown after successful package generation |
| **Clone & re-generate** | `CloneScreen` + `/packages/clone` | Pick an existing package folder, auto-increment iteration, prefill form |
| **Server-form widget** | `ServerForm` widget | Contextual server URL fields per component type in SettingsScreen + NewPackageScreen |
| **Logging** | `AppLogger` + `GET /logs` | Rotating log files for app and API; log viewer screen accessible from sidebar |
| **Auto-updater** | `updateCheckProvider` + `latest.json` | Passive update check on startup; dismissable banner in dashboard |
| **Health indicator** | `healthPollingProvider` + `AppShell` sidebar | Green/red dot; crash detection after 2 failures; restart button |

---

## Theme

Material 3, seed `Colors.blue` (system-default blue). Light and dark themes defined in `app.dart`.

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.light,  // or Brightness.dark
)
```

> **Note**: Brand colors (`kGreenPrimary`, etc.) referenced in older docs/notes are **not present** in the codebase. `constants.dart` defines `kApiPort`, `kBaseUrl`, `kAppVersion`, and `kUpdateCheckUrl`.

---

## Test Commands

```bash
# API tests (120 tests)
cd api
python -m pytest

# Flutter tests (211 tests)
cd app
flutter test

# Single test file
cd app
flutter test test/path/to/file.dart

# Regenerate mocks (after adding/changing providers)
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## Key Files for Context

| File | What it does |
|------|-------------|
| `PROMPT_V3.md` | **Original spec** — authoritative for any domain rule question |
| `ARCHITECTURE.md` | System diagrams, data flow, tech stack, domain model |
| `api/src/mgg_packify_api/routes/packages.py` | `_derive_component_config()` — expansion logic |
| `api/src/mgg_packify_api/services/doc_generator.py` | .docx generation (903 lines) |
| `api/src/mgg_packify_api/services/component.py` | `ComponentType` enum + canonical order |
| `api/src/mgg_packify_api/services/publish_service.py` | IIS publish pipeline (beyond-spec) |
| `app/lib/app.dart` | go_router flat config + ThemeData (seed: `Colors.blue`) |
| `app/lib/core/api_client.dart` | HTTP client + all API methods + `apiClientProvider` |
| `app/lib/core/server_manager.dart` | Python process spawn/kill logic |
| `app/lib/core/constants.dart` | `kApiPort = 8787`, `kBaseUrl` |
| `app/lib/core/app_logger.dart` | Singleton logger with rotating file output to `%LOCALAPPDATA%\MGG Packify\logs\app.log` |
| `app/lib/providers/health_polling_provider.dart` | 30s health poll, crash detection, `ServerStatus.crashed` |
| `app/lib/providers/update_check_provider.dart` | Fetches `latest.json`, semver compare, passive failure |
| `app/lib/screens/log_viewer_screen.dart` | Two-tab log viewer (App / API) |
| `app/lib/screens/about_screen.dart` | Version info + update check button |
| `latest.json` | Auto-updater manifest — `version`, `url`, `release_notes` |
| `build.ps1` | Flutter → PyInstaller → Inno Setup pipeline (flags: `-SkipFlutter`, `-SkipApi`, `-SkipInstaller`) |
| `installer/mgg-packify.iss` | Inno Setup script — installs to `%LOCALAPPDATA%\MGG Packify` |

---

## VS Code Debug Configs

`.vscode/launch.json` has 3 configs:

| Config | What it does |
|--------|-------------|
| **API (Python)** | Runs FastAPI on `:8787` |
| **Flutter (Windows)** | Runs Flutter desktop app |
| **Compound** | Runs both together (recommended for development) |
