# Android Fridge Tablet CI Baseline

## Status: Completed

## Context

`android-fridge-tablet` has an SDK-free Fridge source baseline plus guarded
Gradle gates behind `make check`. The repository needs the same wrapper to run
in GitHub Actions so storage, date, layout, and privacy contracts are checked
before review.

## Objectives

- Run the existing `make check` wrapper in GitHub Actions.
- Run the complete legacy Android gate with a matching hosted SDK.
- Make the workflow presence part of the SDK-free baseline contract.

## Work Completed

- Added `.github/workflows/check.yml` to run `make check` on pushes, pull
  requests, and manual dispatches.
- Pinned setup actions to immutable revisions, limited permissions to
  repository reads, and bounded the job to 15 minutes.
- Install Android API 22 and build-tools 24.0.3, select Java 8, and run the
  complete `make check` gate including lint, unit tests, and debug assembly.
- Use the legacy non-queued PNG cruncher for deterministic clean-runner
  resource processing while preserving aapt validation.
- Extended `scripts/check-baseline.sh` to require the CI workflow and this
  completed plan.
- Disabled persisted checkout credentials and replaced partial string matching
  with a canonical single-workflow contract.
- Added self-protecting CODEOWNERS coverage for the workflow, Makefile, and
  baseline checker; repository rules remain responsible for requiring owner
  approval.
- Updated README, VISION, SECURITY, and CHANGES with the CI baseline.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

## Follow-Up Candidates

- Modernize the legacy Gradle, Android plugin, Commons IO, and API-level build
  baseline in a separate compatibility-focused change.
