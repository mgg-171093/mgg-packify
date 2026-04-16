# cd-release-pipeline Specification

## Purpose

Define automated releases for `main`, using one canonical version and publishing a Windows installer plus update metadata.

## Requirements

### Requirement: Main Branch Release Automation

The system MUST run the release workflow on pushes to `main`. It SHALL read the canonical version from `app/pubspec.yaml` and synchronize that version into `api/pyproject.toml`, `app/lib/core/constants.dart`, `installer/mgg-packify.iss`, `build.ps1`, and `latest.json` before building.

#### Scenario: Synchronize versions before build

- GIVEN a push to `main` changes releasable code
- WHEN the release workflow starts
- THEN all required version consumer files match `app/pubspec.yaml`
- AND the build uses that synchronized version only once

### Requirement: Release Asset and Metadata Publishing

The system MUST generate the Windows installer artifact, publish it as a GitHub Release asset for the synchronized version, and update `latest.json` so it references that same version and download target.

#### Scenario: Publish a releasable build

- GIVEN version synchronization and build steps succeed
- WHEN the workflow publishes the release
- THEN exactly one GitHub Release exists for that version with the installer asset attached
- AND `latest.json` describes that published release version

### Requirement: Anti-Loop and Idempotent Release Behavior

The system MUST prevent workflow-triggered commits, tags, or release updates from recursively retriggering the release pipeline. It MUST treat an already-published version as idempotent by skipping duplicate release creation and avoiding a new commit when `latest.json` already matches the published version.

#### Scenario: Ignore automation-only metadata commit

- GIVEN the workflow commits only the `latest.json` update back to `main`
- WHEN GitHub evaluates workflow triggers for that commit
- THEN the release workflow does not start a second release cycle
- AND repository state remains stable after one successful run

#### Scenario: Re-run the same version safely

- GIVEN a workflow is retried for a version that already has synchronized files, release asset, and metadata
- WHEN the workflow checks publication state
- THEN it does not create duplicate releases, tags, or redundant commits
- AND it reports a no-op or reuse outcome instead of failing unpredictably

### Requirement: Permissions and Secrets Contract

The system MUST declare the minimum permissions required to read repository contents, create releases, and push the automation-authored metadata commit. It MAY rely on `GITHUB_TOKEN` when that token has read/write contents permission, and it MUST fail with a clear error if required permissions or repository settings are missing.

#### Scenario: Missing release permissions

- GIVEN the workflow token cannot publish releases or push metadata
- WHEN the release workflow reaches that operation
- THEN the run fails with a permission-specific error
- AND no partial duplicate release is created silently
