![MGG Packify](docs/branding/banner.png)

[![Version](https://img.shields.io/badge/Version-3.5.0-blue?style=flat-square)](./latest.json)
[![Python](https://img.shields.io/badge/Python-%E2%89%A53.12-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](./LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D4?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows/windows-11)
[![API Tests](https://img.shields.io/badge/API%20Tests-120%20passing-brightgreen?style=flat-square)](./api/)
[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-211%20passing-brightgreen?style=flat-square)](./app/)

Windows 11 desktop app that generates installation packages (`.docx` document + folder structure) for multiple projects and environments. Covers all 8 component types: SQL scripts, API IIS/Docker services, Blob Storage, Liferay builds, Assets, and API Management.

---

## Architecture

Flutter desktop UI spawns a Python FastAPI backend as a child process. All communication happens via HTTP REST on `localhost:8787`. Both processes live entirely on the same Windows machine — no cloud, no network, no external services.

```mermaid
graph TB
    subgraph Windows["Windows 11 Desktop"]
        Flutter["Flutter App<br/>Riverpod 2.x + go_router 14"]
        API["Python FastAPI<br/>uvicorn · port 8787"]
        FS["Filesystem<br/>Package folders + .docx"]
        Config["%APPDATA%\\mgg_packify_api\\<br/>config.json · options.json"]
        Logs["%LOCALAPPDATA%\\MGG Packify\\logs\\<br/>app.log · api.log"]
        SharedPrefs["SharedPreferences<br/>history · templates · theme"]
    end

    Flutter -->|"HTTP REST<br/>localhost:8787"| API
    Flutter -->|"spawn / kill"| API
    API -->|"read / write"| Config
    API -->|"mkdir + docx"| FS
    API -->|"RotatingFileHandler"| Logs
    Flutter -->|"AppLogger"| Logs
    Flutter -->|"read / write"| SharedPrefs
```

> Full system diagrams, sequence diagrams, and provider dependency graph → [`ARCHITECTURE.md`](./ARCHITECTURE.md)

---

## Installation

### Option A — Installer (recommended for end users)

> **Prerequisites**: nothing. The installer bundles everything.

1. Download `MGGPackify-3.5.0-Setup.exe` from [Releases](https://github.com/mgg-171093/mgg-packify/releases)
2. Run the installer — **no admin / UAC required**
3. The app installs to `%LOCALAPPDATA%\MGG Packify\`
4. Launch **MGG Packify** from the Start Menu or Desktop shortcut

On first launch the app starts automatically. Logs are written to `%LOCALAPPDATA%\MGG Packify\logs\`.

### Option B — Build the installer yourself

See [Building the Installer](#building-the-installer) below.

### Option C — Run from source (development)

See [Development Quick Start](#development-quick-start) below.

---

## Building the Installer

To produce `MGGPackify-3.5.0-Setup.exe` from source you need the full dev environment plus two build tools.

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.41.4 | [flutter.dev](https://flutter.dev/docs/get-started/install/windows) |
| Python | ≥ 3.12 | [python.org](https://www.python.org/downloads/) |
| PyInstaller | 6.19.0 | `pip install pyinstaller==6.19.0` |
| Inno Setup | 6.x | [jrsoftware.org/isdl.php](https://jrsoftware.org/isdl.php) |

Install them in order:

```powershell
# 1. Install Python packages
pip install -e api/
pip install pyinstaller==6.19.0

# 2. Install Flutter dependencies
cd app
flutter pub get
cd ..

# 3. Install Inno Setup 6 from https://jrsoftware.org/isdl.php
#    (default install path: C:\Program Files (x86)\Inno Setup 6\)
```

### Run the build

```powershell
# From repo root — full pipeline (Flutter → PyInstaller → Inno Setup)
.\build.ps1

# Skip steps you don't need to redo
.\build.ps1 -SkipFlutter     # skip Flutter build (reuse existing Release output)
.\build.ps1 -SkipApi         # skip PyInstaller (reuse existing mgg-packify-api.exe)
.\build.ps1 -SkipInstaller   # skip Inno Setup (only build app + API, no .exe installer)
```

The script:
1. Builds the Flutter Windows release → `app/build/windows/x64/runner/Release/`
2. Bundles the Python API with PyInstaller → `api/dist/mgg-packify-api.exe` (single-file, ~50 MB)
3. Assembles a `staging/` directory with Flutter output
4. Runs Inno Setup → `installer/Output/MGGPackify-3.5.0-Setup.exe`

> **Note**: PyInstaller + Python 3.12+ may trigger Windows Defender on first run (false positive on bundled executables). This is expected — no code signing is applied yet.

---

## Development Quick Start

### 1 — Clone the repo

```bash
git clone https://github.com/mgg-171093/mgg-packify.git
cd mgg-packify
```

### 2 — Install the API

```bash
# No virtualenv — packages installed globally
pip install -e api/
```

### 3 — Install Flutter dependencies

```bash
cd app
flutter pub get
```

### 4 — Run (VS Code — recommended)

Open the project in VS Code and use the **API + App (full stack)** compound launch config from `.vscode/launch.json`. This starts both processes simultaneously.

### 5 — Run (CLI — two terminals)

```bash
# Terminal 1 — API backend
cd api
python -m mgg_packify_api.main
# → Listening on http://127.0.0.1:8787

# Terminal 2 — Flutter app
cd app
flutter run -d windows
```

The Flutter app polls `GET /health` on startup. Once the API responds, the app navigates to the Home screen.

---

## Testing

```bash
# API — 120 tests
cd api
python -m pytest

# API — verbose
cd api
python -m pytest -v

# Flutter — 211 tests
cd app
flutter test

# Flutter — single file
cd app
flutter test test/providers/settings_provider_test.dart

# Regenerate mocks (after changing providers or ApiClient)
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## Features

### Core

- 📦 **Package generation** — fills a `.docx` Installation Manual from a 5-field form + component selector
- 🗂️ **8 component types** — `liferay_build`, `sql`, `api_iis`, `api_docker`, `blob`, `liferay`, `assets`, `apim`
- 🌍 **Multi-environment** — QA / UAT / PROD with server URL configuration per environment
- 📄 **docx output** — table-based manual with branded header, footer, and "Componentes Afectados" table

### Beyond Original Spec

| Feature | Description |
|---------|-------------|
| **History** | Last 50 generated packages in SharedPreferences — swipe to delete, tap to re-generate |
| **Templates** | Save named component-type templates; quick-apply from Home screen |
| **Dark mode** | System / Light / Dark toggle (Apariencia tab in Settings) — persisted via SharedPreferences |
| **Publish pipeline** | `api_iis` instances with `publicar: true` trigger MSBuild / `dotnet publish` + ZIP output |
| **Image injection** | `ConfigItemIn.imagen_path` embeds a custom image into the generated `.docx` |
| **Toast notifications** | Windows native toast shown after every successful package generation |
| **Clone & re-generate** | Pick an existing package folder, auto-increment iteration, prefill the form |
| **Server form widget** | Contextual server URL fields per component type in Settings and NewPackage screens |
| **Logging** | Rotating file logs in `%LOCALAPPDATA%\MGG Packify\logs\` — `app.log` + `api.log` (5 MB, 3 backups) |
| **Auto-updater** | Passive update check on startup — dismissable banner when a new version is available |
| **Health indicator** | Persistent green/red dot in sidebar; "Reiniciar API" button on crash |
| **Log viewer** | In-app viewer for `app.log` and `api.log` with refresh (Settings → Logs) |
| **About screen** | App + API version, GitHub link, manual update check |
| **Installer** | Single `.exe` installer via Inno Setup — no admin required, installs to `%LOCALAPPDATA%` |

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| UI | Flutter (Windows) | 3.41.4 | Desktop UI framework |
| UI | Dart | 3.11.1 | Language |
| UI | flutter_riverpod | ^2.5.0 | State management |
| UI | go_router | ^14.0.0 | Flat declarative routing |
| UI | http | ^1.2.0 | HTTP client for API calls |
| UI | logger | ^2.4.0 | Structured rotating file logging |
| UI | shared_preferences | ^2.3.0 | Local persistence (history, templates, theme) |
| UI | google_fonts | ^6.2.0 | Typography |
| UI | file_picker | ^8.0.0 | Folder selection dialogs |
| UI | url_launcher | ^6.3.0 | Open output folder / GitHub links in browser |
| UI | local_notifier | ^0.1.4 | Windows native toast notifications |
| UI | path | ^1.9.0 | Cross-platform path utilities |
| API | Python | ≥3.12 | Backend language |
| API | FastAPI | ^0.110 | REST framework |
| API | uvicorn[standard] | ^0.29 | ASGI server |
| API | python-docx | ^1.0 | `.docx` generation |
| API | pydantic | ^2.0 | Request / response validation |
| API | platformdirs | ^4.0 | `%APPDATA%` path resolution |
| Build | PyInstaller | 6.19.0 | Bundle Python API to single `.exe` |
| Build | Inno Setup | 6.x | Windows installer (no UAC) |

---

## Prerequisites (development)

| Requirement | Version | Notes |
|-------------|---------|-------|
| Python | ≥ 3.12 | No virtualenv — global install |
| Flutter | 3.41.4 | Windows desktop target must be enabled |
| Windows | 11 | Target platform only |
| VS Code | Any recent | Recommended: Flutter + Python extensions |

---

## Data Paths

| What | Path |
|------|------|
| App install dir | `%LOCALAPPDATA%\MGG Packify\` |
| App log | `%LOCALAPPDATA%\MGG Packify\logs\app.log` |
| API log | `%LOCALAPPDATA%\MGG Packify\logs\api.log` |
| Server config | `%APPDATA%\mgg_packify_api\config.json` |
| Option lists | `%APPDATA%\mgg_packify_api\options.json` |
| History / templates / theme | Windows `SharedPreferences` (registry-backed) |

Config and options in `%APPDATA%` are **never overwritten on upgrade** — your settings survive updates.

---

## Project Documentation

| File | Audience | Contents |
|------|----------|---------|
| [`PROMPT_V3.md`](./PROMPT_V3.md) | All | **Source of truth** — original 755-line specification |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Devs / AI | System diagrams, data flow, provider graph, screen flow, folder output tree |
| [`AGENTS.md`](./AGENTS.md) | AI agents | Critical rules, domain quick-ref, file map, test commands |
| [`api/AGENTS.md`](./api/AGENTS.md) | AI (API) | All endpoints with JSON examples, generate pipeline diagram, Python gotchas |
| [`app/AGENTS.md`](./app/AGENTS.md) | AI (Flutter) | All screens, providers, widgets, navigation rules, Dart gotchas |
| [`api/README.md`](./api/README.md) | API devs | API install, run, test, endpoint table, config paths |
| [`app/README.md`](./app/README.md) | Flutter devs | Flutter run, test, lint, mock regen commands |

---

## Contributing

Before touching any code, read [`AGENTS.md`](./AGENTS.md) — it contains critical rules that prevent subtle bugs.

### Key constraints

| Rule | Detail |
|------|--------|
| **No virtualenv** | `pip install -e api/` installs globally — never create a venv |
| **All tests must pass** | Run `python -m pytest` (API) + `flutter test` (Flutter) after every change |
| **Navigation** | Always `context.go('/route')` — never `Navigator.pop()` or `context.pop()` (flat router, no stack) |
| **State management** | Never call `AsyncNotifier.update()` — use the custom `save()` method on each notifier |
| **Port 8787** | Hardcoded in both Flutter (`constants.dart`) and API (`main.py`) — do NOT change |
| **Dialog exception** | `Navigator.of(ctx).pop()` inside `showDialog` builders is the ONE valid Navigator use |

### Dev workflow

```bash
# 1. Make your changes
# 2. Run API tests
cd api && python -m pytest

# 3. Run Flutter tests
cd app && flutter test

# 4. If you changed providers or ApiClient — regenerate mocks
cd app && dart run build_runner build --delete-conflicting-outputs

# 5. Lint
cd api && ruff check . && ruff format --check .
cd app && flutter analyze && dart format --set-exit-if-changed .
```

---

## License

[MIT](./LICENSE) © 2026 Manuel Garcia Gonzalez
