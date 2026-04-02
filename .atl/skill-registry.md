# Skill Registry — mgg-packify (mgg-packgen v3)

> Last updated by sdd-apply (project-docs-overhaul, task 7.1). Do not edit manually.

## Project Conventions

| File | Type | Description |
|------|------|-------------|
| `AGENTS.md` | Agent Context | Root-level AI context: domain rules, critical gotchas, test commands |
| `api/AGENTS.md` | Agent Context | Python API-specific context: routes, expansion logic, gotchas |
| `app/AGENTS.md` | Agent Context | Flutter app-specific context: providers, navigation rules, gotchas |
| `PROMPT_V3.md` | Specification | Complete project specification (755 lines) — source of truth for domain rules |
| `ARCHITECTURE.md` | Architecture | Tech stack, patterns, data flow, API endpoints, test coverage |

---

## Stack

**This project is Flutter (Windows) + Python (FastAPI). There is NO Go code.**

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.41.2 (Windows desktop) |
| State | Riverpod 2.x (`Notifier` / `AsyncNotifier` / `StateProvider` / `FutureProvider.family`) |
| Navigation | go_router (flat config, no Navigator stack) |
| Backend | Python 3.12 + FastAPI + uvicorn on port 8787 |
| Persistence | SharedPreferences (Flutter) + `%APPDATA%\mgg_packgen_api\` (Python) |

---

## Critical Project-Specific Conventions

These conventions MUST be followed by any agent working on this codebase. Violating them causes hard-to-detect bugs.

### Navigation (Flutter)

- **ALWAYS** use `context.go('/route')` — go_router flat config, no navigation stack
- **NEVER** use `Navigator.pop()` or `context.pop()` for route transitions
- **EXCEPTION**: `Navigator.of(ctx).pop()` IS permitted **inside dialog builders** to close the dialog — this does NOT violate the rule (dialogs are not routes)

### State Management (Flutter — Riverpod 2.x)

- **NEVER** call `AsyncNotifier.update()` — it is a reserved Riverpod framework method and will throw
- User-triggered saves MUST use a custom `save()` method defined on the notifier class
- `packageFormProvider` is a **sync `Notifier`** (NOT `AsyncNotifier`) — no async state needed
- All `AsyncNotifier` subclasses expose a `save()` method for persistence

### Mock Regeneration (Flutter)

- After changing any provider or injectable class, regenerate mocks with:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- Running tests without regenerating mocks after provider changes will produce stale/incorrect test results

### Python API

- **No virtualenv** — packages are installed globally; never create or activate a venv
- Port **8787** is hardcoded in both Flutter (`api_client.dart`) and Python (`main.py`) — do NOT change it
- Run API: `cd api && python -m mgg_packgen_api.main`
- Run tests: `cd api && python -m pytest` (61 tests)

---

## Auto-Load Skill Triggers

When you detect any of the following contexts, load the corresponding skill **before writing any code**.

### Flutter / Dart Patterns

| Context Detected | Load Skill | Why |
|-----------------|-----------|-----|
| Navigation code touching routes | *(no dedicated skill)* | Follow `context.go()` rule manually — see Critical Conventions above |
| Provider code, `AsyncNotifier`, `save()`, state management | *(no dedicated skill)* | Follow Riverpod 2.x rules manually — see Critical Conventions above |
| Mock generation, `build_runner`, Mockito | *(no dedicated skill)* | Run `dart run build_runner build --delete-conflicting-outputs` |
| Writing Flutter tests, widget tests, provider tests | *(no dedicated skill)* | Follow project test conventions in `app/AGENTS.md` |

### Go Tests

| Context Detected | Load Skill | Why |
|-----------------|-----------|-----|
| ~~Go tests, teatest, Bubbletea TUI~~ | ~~`go-testing`~~ | **N/A — this project has NO Go code. Flutter + Python only. Do not load.** |

### AI / Agent Skills

| Context Detected | Load Skill | Why |
|-----------------|-----------|-----|
| Creating a new skill, documenting AI agent patterns | `skill-creator` | Ensures new skills follow the Agent Skills spec |

---

## Available Skills

### SDD Workflow Skills (orchestrator-managed)

| Skill | Trigger | Location |
|-------|---------|----------|
| `sdd-init` | Initialize SDD in a project, "sdd init", "iniciar sdd" | `~/.config/opencode/skills/sdd-init/SKILL.md` |
| `sdd-explore` | Explore/investigate ideas before committing to a change | `~/.config/opencode/skills/sdd-explore/SKILL.md` |
| `sdd-propose` | Create a change proposal with intent, scope, and approach | `~/.config/opencode/skills/sdd-propose/SKILL.md` |
| `sdd-spec` | Write specifications with requirements and scenarios | `~/.config/opencode/skills/sdd-spec/SKILL.md` |
| `sdd-design` | Create technical design document with architecture decisions | `~/.config/opencode/skills/sdd-design/SKILL.md` |
| `sdd-tasks` | Break down a change into an implementation task checklist | `~/.config/opencode/skills/sdd-tasks/SKILL.md` |
| `sdd-apply` | Implement tasks from the change, writing actual code | `~/.config/opencode/skills/sdd-apply/SKILL.md` |
| `sdd-verify` | Validate that implementation matches specs, design, and tasks | `~/.config/opencode/skills/sdd-verify/SKILL.md` |
| `sdd-archive` | Sync delta specs to main specs and archive a completed change | `~/.config/opencode/skills/sdd-archive/SKILL.md` |

### DevOps / Collaboration Skills

| Skill | Trigger | Location |
|-------|---------|----------|
| `issue-creation` | Creating a GitHub issue, reporting a bug, requesting a feature | `~/.config/opencode/skills/issue-creation/SKILL.md` |
| `branch-pr` | Creating a pull request, opening a PR, preparing changes for review | `~/.config/opencode/skills/branch-pr/SKILL.md` |

### Review Skills

| Skill | Trigger | Location |
|-------|---------|----------|
| `judgment-day` | "judgment day", "review adversarial", "dual review", "juzgar" | `~/.config/opencode/skills/judgment-day/SKILL.md` |

### Testing Skills

| Skill | Trigger | Notes | Location |
|-------|---------|-------|----------|
| `go-testing` | ~~Writing Go tests, using teatest~~ | **NOT APPLICABLE** — No Go code in this project (Flutter + Python only) | `~/.config/opencode/skills/go-testing/SKILL.md` |

### Meta Skills

| Skill | Trigger | Location |
|-------|---------|----------|
| `skill-creator` | Creating a new skill, adding agent instructions, documenting patterns | `~/.config/opencode/skills/skill-creator/SKILL.md` |

---

## Notes

- **Project-level skills**: None found (no `.claude/skills/`, `.gemini/skills/`, `.agent/skills/`, or `skills/` directories)
- **User-level source**: `C:\Users\manue\.config\opencode\skills\`
- Skills `sdd-*` and `_shared` are excluded from auto-load triggers (they are orchestrator-dispatched)
- **`go-testing` is explicitly NOT applicable** to this project — it targets Go/Bubbletea TUI patterns which do not exist here
- Stack-specific auto-load rules: New AI skills → `skill-creator`
