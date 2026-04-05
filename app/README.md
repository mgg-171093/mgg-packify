# MGG-Packify — Flutter App

Flutter Windows desktop app for **MGG-Packify — Portal Retail Skandia México**.  
Generates installation packages (`.docx` + folder structure) for Portal Retail deployments.
Communicates with a local Python FastAPI backend via HTTP REST on `localhost:8787`.

→ See [app/AGENTS.md](./AGENTS.md) for AI-agent context (screens, providers, widgets, gotchas).  
→ See [root AGENTS.md](../AGENTS.md) for domain rules and critical context.

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter | 3.x (Dart SDK `^3.11.0`) |
| OS | Windows 11 |
| Python | ≥ 3.12 (for the API backend) |

---

## Run

```bash
cd app
flutter run -d windows         # debug mode
flutter build windows          # production build
```

The app auto-spawns the Python API on startup (dev mode: skips spawn if port 8787 already active).

---

## Test

```bash
cd app
flutter test                   # run all 161 tests
flutter test test/path/file.dart  # run a single test file
```

All tests must remain green after any change.

---

## Mock Regeneration

After adding or changing `mockito` mocks, regenerate them:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

---

## Lint & Format

```bash
cd app
flutter analyze                # static analysis
dart format .                  # auto-format
```

---

## Critical Rules

These rules apply to **every** change in this codebase. Violating any of them breaks the app.

| Rule | ✅ Correct | ❌ Never do |
|------|-----------|------------|
| **Navigation** | `context.go('/home')` | `Navigator.pop(context)` or `context.pop()` |
| **State mutations** | Custom `save()` method on notifier | `await update((s) => ...)` — reserved Riverpod method |
| **Python side** | Packages installed globally | Do NOT introduce a virtualenv |
| **Tests** | All 161 tests green before merging | Never leave a failing test |

### Why no `Navigator.pop()`?

go_router is configured as a **flat router** — there is no navigation stack. Calling `Navigator.pop()`
or `context.pop()` will either crash or navigate to an unexpected screen. Every "back" action must
call `context.go('/parent-route')` explicitly.

### Why no `AsyncNotifier.update()`?

`update()` is a **reserved method** in the Riverpod framework. Calling it causes a runtime error.
All state mutations use a custom `save()` method pattern instead.

---

## Project Documentation

| Document | Description |
|----------|-------------|
| [app/AGENTS.md](./AGENTS.md) | Screens, providers, widgets, navigation rules — for AI agents and developers |
| [AGENTS.md](../AGENTS.md) | Root agent context — domain rules, component types, critical gotchas |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | System design, mermaid diagrams, data flow, tech stack |
| [README.md](../README.md) | Root project overview — features, quick start, badges |

---

*Part of [MGG-Packify](../README.md) — Portal Retail Skandia México*
