# mgg-packify

Portal Retail Skandia Mexico — Windows desktop app that generates installation packages (.docx + folder structure).

## Architecture

Flutter desktop UI spawns a Python FastAPI backend as a child process.
Communication via HTTP REST on `localhost:8787`.

```
mgg-packgen-v3/
├── api/    ← Python FastAPI backend
└── app/    ← Flutter Windows desktop app
```

## Prerequisites

- **Python** >= 3.12
- **Flutter** >= 3.11 (Windows desktop enabled)
- **Windows 11** (target platform)

## Quick Start

### Install dependencies

```bash
# API (no virtualenv — global install)
pip install -e api/

# Flutter
cd app
flutter pub get
```

### Run (VS Code)

Use the **API + App (full stack)** compound launch config in `.vscode/launch.json`.

### Run (CLI)

```bash
# Terminal 1 — API
cd api
python -m mgg_packgen_api.main

# Terminal 2 — Flutter
cd app
flutter run -d windows
```

## Tests

```bash
# API — 61 tests
cd api
python -m pytest

# Flutter — 96 tests
cd app
flutter test
```

## Project Documentation

| File | Purpose |
|------|---------|
| `PROMPT_V3.md` | Original spec — source of truth for domain rules |
| `ARCHITECTURE.md` | Tech stack, patterns, data flow |
| `AGENTS.md` | AI agent context (root) |
| `api/AGENTS.md` | AI agent context (API) |
| `app/AGENTS.md` | AI agent context (Flutter) |

## License

MIT
