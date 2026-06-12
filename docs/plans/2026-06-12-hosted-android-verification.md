# Hosted Android Verification

## Status: Completed

## Context

The canonical workflow clears Android SDK variables and runs only source
contracts. The current PR head passes Android lint with zero findings, both
unit-test variants, and debug assembly locally with Android API 22,
build-tools 24.0.3, and Java 8.

This project uses AGP 1.1, whose concurrent `QueuedCruncher` can fail
nondeterministically on clean hosted runners. The plugin supports its legacy
non-queued cruncher without skipping aapt resource validation.

## Goal

Run the proven complete Android gate in hosted CI with deterministic resource
processing.

## Changes

- Install platform-tools, Android API 22, and build-tools 24.0.3 before
  selecting Java 8.
- Run canonical `make check` with a 15-minute timeout.
- Select AGP 1.1's non-queued PNG cruncher for clean-runner stability.
- Preserve immutable actions, read-only permissions, disabled checkout
  credentials, and the byte-exact workflow checker.
- Update README and CI plan evidence.

## Verification

- Passed SDK-backed `make check` from the repository root with zero lint issues.
- Passed the complete gate from an external fresh disposable clone.
- Confirmed nine hostile workflow, cruncher, checker, documentation, and
  plan-status mutations are rejected.
- Passed `git diff --check`.
- GitHub Actions `pull_request` run `27401692406` passed the complete hosted
  Android gate in 41 seconds for implementation commit
  `e822f40bbf3dc505ba8e769de3245febe44e36ae`.

## Boundaries

- Do not change target SDK 21 or modernize Gradle, AGP, or Commons IO.
- Do not weaken storage failure handling or add permissions.
- Do not add credentials, signing material, or dependencies.
