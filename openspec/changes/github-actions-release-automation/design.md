# Design: GitHub Actions Release Automation

## Technical Approach

Two workflow files (`ci.yml`, `release.yml`) on `windows-latest` runners. A PowerShell helper (`scripts/sync-version.ps1`) reads the canonical version from `pubspec.yaml` and patches all 5 remaining files. The release workflow uses `[skip ci]` + `paths-ignore` as a double-guard against infinite loops. `GITHUB_TOKEN` handles all git and release operations — no PATs needed.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|-------------|-----------|
| Canonical version source | `app/pubspec.yaml` | Dedicated `VERSION` file; `package.json`-style | Already the primary manifest; Flutter reads it natively; avoids adding yet another file |
| Runner OS | `windows-latest` for both CI and CD | Ubuntu + cross-compile | Flutter Windows build requires Windows SDK; PyInstaller must target Windows; Inno Setup is Windows-only |
| Loop prevention | `[skip ci]` commit message AND `paths-ignore: ['latest.json']` | Separate bot token; conditional `if` on actor | Double-guard is simplest and needs no secrets management; `paths-ignore` alone is insufficient if other files change in the same push |
| Git operations in release | `GITHUB_TOKEN` with default write permissions | Deploy key; PAT | `GITHUB_TOKEN` is auto-provisioned, scoped to the repo, and expires after the job — zero secret management |
| Release creation | `gh release create` CLI | `actions/create-release`; REST API via curl | `gh` is pre-installed on runners; single command; supports asset upload inline |
| Version sync tool | PowerShell script (`sync-version.ps1`) | sed/awk; Node script; Python script | Project already uses PowerShell (`build.ps1`); consistent tooling; native on Windows runners |

## Data Flow

```
push to main
    │
    ▼
release.yml triggers (paths-ignore: latest.json)
    │
    ├─ Step 1: checkout
    ├─ Step 2: read version from pubspec.yaml → $VERSION
    ├─ Step 3: sync-version.ps1 patches 5 files
    ├─ Step 4: setup Flutter + Python + Inno Setup
    ├─ Step 5: flutter test + python -m pytest
    ├─ Step 6: build.ps1 → MGGPackify-$VERSION-Setup.exe
    ├─ Step 7: gh release create v$VERSION-stable --attach .exe
    ├─ Step 8: update latest.json (version + url + release_notes)
    └─ Step 9: git commit latest.json with [skip ci] → push to main
```

```
push/PR to develop
    │
    ▼
ci.yml triggers
    ├─ flutter test (app/)
    └─ python -m pytest (api/)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `.github/workflows/ci.yml` | Create | CI: lint + test on PR and push to `develop` |
| `.github/workflows/release.yml` | Create | CD: version sync, build, GitHub Release, `latest.json` commit |
| `scripts/sync-version.ps1` | Create | Reads `pubspec.yaml` version, patches `pyproject.toml`, `constants.dart`, `mgg-packify.iss`, `build.ps1`, `latest.json` |
| `build.ps1` | Modify | Accept `$Version` from env var `MGG_VERSION` if set (fallback to current hardcoded value); remove hardcoded `$PythonExe` path for CI portability |
| `latest.json` | Modify | Auto-updated by release workflow (version, url, release_notes) |

## Interfaces / Contracts

```powershell
# scripts/sync-version.ps1 — interface
# Input: reads version from app/pubspec.yaml line matching "version: X.Y.Z+N"
# Extracts semver portion (X.Y.Z), ignores build number (+N)
# Patches these files with regex replacements:
#   api/pyproject.toml        → version = "X.Y.Z"
#   app/lib/core/constants.dart → kAppVersion = 'X.Y.Z'
#   installer/mgg-packify.iss → #define AppVersion "X.Y.Z"
#   build.ps1                 → $Version = "X.Y.Z"
#   latest.json               → "version": "X.Y.Z" + url with tag
# Output: writes patched files in-place; prints summary to stdout
```

```yaml
# release.yml — permissions block
permissions:
  contents: write  # push commits + create releases
```

```yaml
# release.yml — trigger with anti-loop guard
on:
  push:
    branches: [main]
    paths-ignore: ['latest.json']
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `sync-version.ps1` correctness | Local PowerShell test: create temp copies of all 6 files, run script, assert patched values match expected |
| Integration | Full workflow YAML validity | `actionlint` (can run locally or as CI step) |
| Smoke | Release workflow end-to-end | Manual: push a version bump to `main` on a test branch first; verify GitHub Release appears with correct tag, asset, and `latest.json` update |
| Guard | `[skip ci]` prevents loop | Verify the `latest.json`-only commit does NOT trigger another `release.yml` run (observable in Actions tab) |

## Migration / Rollout

No migration required. All changes are additive — no existing code behavior changes. The `build.ps1` modification is backward-compatible (env var override with fallback). Rollback: delete/disable the two workflow files.

## Open Questions

- [x] All resolved — no blockers for implementation.
