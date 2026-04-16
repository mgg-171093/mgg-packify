# Apply Progress

**Change**: github-actions-release-automation  
**Mode**: Standard  
**Batch**: Continuation remediation batch (verify-fail fixes)

## Completed Tasks

- [x] 1.1 Create `.github/workflows/ci.yml` with triggers for `pull_request` and `push` to `develop`, plus concurrency to cancel superseded runs.
- [x] 1.2 Create `.github/workflows/release.yml` with trigger `push` to `main` and `paths-ignore: ['latest.json']` to guard metadata-only pushes.
- [x] 1.3 Add explicit `permissions` in `release.yml` (`contents: write`) and fail-fast shell settings for deterministic CI/CD behavior.
- [x] 1.4 Pin runtime setup in both workflows (Flutter and Python versions/actions) so runs are reproducible on `windows-latest`.
- [x] 2.1 Create `scripts/sync-version.ps1` to read canonical version from `app/pubspec.yaml` (`X.Y.Z+N`), extract `X.Y.Z`, and validate parse errors.
- [x] 2.2 Implement patch operations in `scripts/sync-version.ps1` for `api/pyproject.toml`, `app/lib/core/constants.dart`, and `installer/mgg-packify.iss`.
- [x] 2.3 Extend `scripts/sync-version.ps1` to patch `build.ps1` and `latest.json`, and print a structured summary of updated targets.
- [x] 2.4 Modify `build.ps1` to consume `MGG_VERSION` (with safe fallback) and remove machine-specific Python path assumptions for runner portability.
- [x] 3.1 Implement CI job steps in `.github/workflows/ci.yml`: checkout, toolchain setup, `flutter test` in `app/`, `python -m pytest` in `api/`.
- [x] 3.2 Implement release preflight in `.github/workflows/release.yml`: checkout full history, run `scripts/sync-version.ps1`, and verify git diff is expected.
- [x] 3.3 Add release validation steps in `release.yml` to run `flutter test` and `python -m pytest` before any build/publish action.
- [x] 3.4 Add build + publish steps in `release.yml`: invoke `build.ps1`, resolve installer path, and run `gh release create` with versioned tag and `.exe` asset.
- [x] 4.1 Add release existence/idempotency check in `release.yml` (skip create if tag already exists) and surface clear no-op logs.
- [x] 4.2 Implement `latest.json` update logic in `release.yml` so version/url/release_notes align to the published release artifact.
- [x] 4.3 Commit and push `latest.json` only when changed, using message containing `[skip ci]`; skip commit/push when no diff exists.
- [x] 4.4 Document required repo setting (“Workflow permissions: Read and write”) in `README.md` or `ARCHITECTURE.md` for predictable token behavior.
- [x] 5.1 Add a local dry-run command section in `README.md` for `scripts/sync-version.ps1` using temporary copies and expected file diff checks.
- [x] 5.2 Validate workflow syntax for `.github/workflows/ci.yml` and `.github/workflows/release.yml` with `actionlint` (local or CI step).
- [x] 6.1 Update both workflows to install Python test dependencies with dev extras before invoking `python -m pytest`.
- [x] 6.2 Implement automatic semantic version increment on `main` release runs using conventional commit policy (`BREAKING CHANGE`/`!` → major, `feat` → minor, otherwise patch).
- [x] 6.3 Persist synchronized version-bearing files back to `main` in the release metadata commit (not only `latest.json`).
- [x] 6.4 Strengthen anti-loop guard so bot-authored `[skip ci]` release metadata commits cannot retrigger the release job.
- [x] 6.5 Update release automation documentation and apply-progress evidence for the remediation behavior.

## Validation

- `pwsh -NoProfile -File scripts/sync-version.ps1` ✅ (idempotent run, all targets reported unchanged)
- `py -m pytest` from `api/` ✅ (120 passed)
- `flutter test` from `app/` ✅ (244 passed)
- `python -m pytest` from `api/` ⚠️ fails in this shell due to PATH resolving to Inkscape Python without pytest; workflow reliability is now ensured via `pip install -e "api[dev]"`
- Local `actionlint` execution ❌ unavailable (`actionlint` and `choco` are not installed in this environment)
- CI workflow includes `actionlint` execution step to validate workflow syntax in runner context ✅

## Deviations from Design

- Minor enhancement: release workflow includes an asset-upload fallback (`gh release upload`) when a release tag already exists but the expected installer asset is missing.
- Rationale: improves idempotency safety for partial prior releases while preserving the “skip duplicate release creation” requirement.
- Added a stronger anti-loop gate: release job now short-circuits when actor is `github-actions[bot]` or head commit contains `[skip ci]`, so metadata commits that touch more than `latest.json` remain safe.

## Issues Found

- Local machine lacks Chocolatey and actionlint binaries, so direct local `actionlint` execution could not be completed in this batch.
- Remote validation remains covered by the CI step in `.github/workflows/ci.yml`.
- Branch-execution verification in GitHub Actions (tasks 5.3/5.4) remains pending because this apply batch does not publish a real release.

## Remaining Tasks

- [ ] 5.3 Execute branch-based verification: push to `develop` confirms CI gates; controlled `main` release confirms one Release, one asset, and one metadata commit.
- [ ] 5.4 Confirm anti-loop behavior in Actions history: `latest.json` automation commit does not trigger a second `release.yml` run.

## Status

23/25 tasks complete. Ready for verify after repository-level branch execution checks (tasks 5.3 and 5.4).
