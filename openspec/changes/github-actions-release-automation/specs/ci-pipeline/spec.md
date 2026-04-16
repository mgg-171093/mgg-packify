# ci-pipeline Specification

## Purpose

Define mandatory validation for pull requests and pushes to `develop` before release automation is allowed to proceed.

## Requirements

### Requirement: Pull Request and Develop Validation

The system MUST run the CI workflow on every pull request and on every push to `develop`. The workflow SHALL execute Flutter tests from `app/` and Python tests from `api/` on a Windows runner, and it MUST fail the run if either suite fails.

#### Scenario: Validate a pull request

- GIVEN a pull request targets the repository
- WHEN the CI workflow starts
- THEN both Flutter and Python test suites run
- AND the check result is failed if any suite fails

#### Scenario: Validate a develop push

- GIVEN a commit is pushed to `develop`
- WHEN the CI workflow starts
- THEN the same validation steps run without requiring manual input
- AND a passing run proves the branch is release-eligible

### Requirement: Deterministic Workflow Inputs

The system MUST provision the pinned toolchains and repository contents needed by both test suites, and it MUST NOT require local developer state, virtual environments, or manual secrets beyond repository defaults.

#### Scenario: Run in a clean runner

- GIVEN a fresh GitHub-hosted runner
- WHEN the CI workflow executes
- THEN it can install the declared Flutter and Python runtimes and run tests successfully
- AND the result is reproducible from repository state alone
