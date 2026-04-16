## Exploration: github-actions-release-automation

### Current State
Currently, the release process is completely manual. The project requires compiling a Flutter Windows application, generating a Python FastAPI executable via PyInstaller, and packaging both using Inno Setup via `build.ps1`. Version numbers are hardcoded in multiple places across the codebase.

### Affected Areas
- `app/pubspec.yaml` — Flutter version
- `api/pyproject.toml` — Python API version
- `app/lib/core/constants.dart` — App version constant (`kAppVersion`)
- `installer/mgg-packify.iss` — Inno Setup `#define AppVersion`
- `latest.json` — Auto-updater target file
- `build.ps1` — Build script version variable

### Approaches
1. **GitHub Actions with `windows-latest` Runner** — Full CI/CD
   - Pros: Automates the entire process; `windows-latest` supports Flutter, Python/PyInstaller, and Inno Setup (which comes pre-installed or can be added via choco). Releases are built natively.
   - Cons: Windows runners consume 2x Action minutes. We need to handle PAT or GITHUB_TOKEN permissions to push commits back to `main` for `latest.json` synchronization without infinite trigger loops.
   - Effort: Medium

2. **Cross-Compilation (Linux runner)** — Build Windows artifacts from Linux
   - Pros: Faster, cheaper CI minutes.
   - Cons: Not natively supported for PyInstaller or Flutter Windows builds. Too fragile and practically impossible to guarantee correct execution of the generated Python `.exe` and Inno Setup without a Windows environment.
   - Effort: High

### Recommendation
**Approach 1 (GitHub Actions with `windows-latest` Runner)**. Since the target is specifically Windows 11 (Flutter Desktop + PyInstaller `.exe` + Inno Setup), we absolutely need a Windows runner to guarantee stability. We should use a single file (like `pubspec.yaml` or a new `version.txt`) as the source of truth, and write a script that injects this version into all other files during the CI/CD pipeline, avoiding manual duplication. The pipeline should trigger on push to `develop` for CI validation, and on tag/push to `main` for full releases. `latest.json` can be updated natively via the release pipeline using the `GITHUB_TOKEN`.

### Risks
- **Infinite Loops**: Pushing back the updated `latest.json` to `main` could trigger the pipeline again if trigger filters (e.g., `[skip ci]`) are not properly configured.
- **Dependencies**: Ensuring the correct exact Python version and Flutter SDK are matched in the runner.

### Ready for Proposal
Yes. The orchestrator can proceed with creating the full technical proposal based on the Windows runner approach and centralized versioning script.