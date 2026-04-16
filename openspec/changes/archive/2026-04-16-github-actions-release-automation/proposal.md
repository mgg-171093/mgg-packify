# Proposal: GitHub Actions Release Automation

## Intent

The release process is entirely manual: version strings are hardcoded in six files, builds require a developer machine, and no GitHub Release is ever produced automatically. This change introduces full CI/CD via GitHub Actions so that every push to `main` produces a versioned Windows installer, publishes a GitHub Release, and updates `latest.json` — with zero manual steps.

## Scope

### In Scope
- CI workflow: lint/test on PRs and pushes to `develop`
- CD workflow: version sync, build, GitHub Release creation, `latest.json` update on push to `main`
- Centralized version source-of-truth (`pubspec.yaml`) injected into all six files at workflow time
- Anti-loop guard so the automated `latest.json` commit does not re-trigger the CD workflow
- Windows Installer (`.exe`) uploaded as a GitHub Release asset

### Out of Scope
- Signing / code-signing the installer
- Multi-platform builds (macOS, Linux)
- Changelog generation beyond GitHub's auto-generated release notes
- Dependency update bots

## Capabilities

### New Capabilities
- `ci-pipeline`: PR and develop-branch validation (Flutter tests, Python tests)
- `cd-release-pipeline`: Full release automation on main — version sync, build, publish

### Modified Capabilities
- None

## Approach

Use a single `windows-latest` runner. Two workflow files:

1. **`ci.yml`** — triggered on `pull_request` and `push` to `develop`
   - `flutter test` in `app/`
   - `python -m pytest` in `api/`

2. **`release.yml`** — triggered on `push` to `main` (path-filtered to avoid infinite loops; `latest.json` commits tagged `[skip ci]`)
   - Read version from `pubspec.yaml`
   - Inject version into `api/pyproject.toml`, `app/lib/core/constants.dart`, `installer/mgg-packify.iss`, `latest.json`, `build.ps1`
   - Run `build.ps1 -SkipFlutter:$false -SkipApi:$false -SkipInstaller:$false`
   - Create GitHub Release via `gh release create` with the `.exe` asset
   - Commit and push updated `latest.json` back to `main` with `[skip ci]` in the commit message

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.github/workflows/ci.yml` | New | CI workflow |
| `.github/workflows/release.yml` | New | CD release workflow |
| `scripts/sync-version.ps1` | New | PowerShell helper — reads `pubspec.yaml`, patches all 6 files |
| `build.ps1` | Modified | Accept externally injected version (env var) instead of hardcoded |
| `latest.json` | Modified | Auto-updated by CD pipeline after each release |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Infinite trigger loop from `latest.json` push | Med | `[skip ci]` commit message + `paths-ignore: ['latest.json']` filter |
| Python/Flutter SDK version drift in runner | Low | Pin exact versions via `flutter-action` and `setup-python` steps |
| `GITHUB_TOKEN` lacking push permissions | Low | Enable "Read and write permissions" for workflows in repo settings |
| Build time > 60 min (Windows runner timeout) | Low | Monitor; `windows-latest` typically completes in ~25 min for this stack |

## Rollback Plan

Delete or disable `.github/workflows/release.yml`. Releases are published to GitHub; previously released assets remain intact. No production code changes — all automation is additive.

## Dependencies

- GitHub Actions `windows-latest` runner (available on public repos, free tier)
- `flutter-action` GitHub Action (community, pinned to hash)
- `setup-python` GitHub Action (official)
- Inno Setup (pre-installed on `windows-latest` or installable via Chocolatey)

## Success Criteria

- [ ] Push to `develop` triggers CI; both test suites pass
- [ ] Push to `main` triggers CD; a GitHub Release is created with the `.exe` installer asset
- [ ] All six version files reflect the correct version after release
- [ ] `latest.json` is committed back to `main` without re-triggering the release workflow
- [ ] No manual developer action is required to cut a release
