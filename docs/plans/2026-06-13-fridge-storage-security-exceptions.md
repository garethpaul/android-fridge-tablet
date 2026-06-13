# Handle Fridge Storage Security Exceptions

Status: Completed

## Context

The fridge persistence boundaries fail closed for `IOException`, but Android
file access can also throw `SecurityException`. Those failures currently escape
the activity instead of using the existing unavailable-state or rollback paths.

## Requirements

- R1. Read-time `SecurityException` failures must mark storage unavailable,
  preserve the empty in-memory list, use the generic read log, and show the
  localized read error.
- R2. Write-time `SecurityException` failures must return `false`, retain
  permission-safe temporary-file cleanup, and use generic write/cleanup logs so
  callers preserve their existing add/delete rollback behavior.
- R3. Catch only `IOException` and `SecurityException`; do not add broad
  `RuntimeException`, `Exception`, or `Throwable` handling.
- R4. UTF-8 encoding, atomic same-directory writes, item normalization,
  receiver/UI behavior, dependencies, and workflows must remain unchanged.
- R5. SDK-free contracts must isolate both catch boundaries and reject removal,
  broadening, or loss of existing failure behavior.

## Verification

- SDK-backed `make check` when the configured Android SDK is available.
- External-working-directory baseline execution.
- `sh -n scripts/check-baseline.sh` and `git diff --check`.
- Focused hostile mutations for missing read/write security catches, broad
  catches, lost read fail-closed state, stale plan status, and missing evidence.
- Exact-base artifact and credential-shaped added-line inspection.
- Exact-head hosted Android validation after push.

## Work Completed

- Routed read and write `SecurityException` failures through the existing
  `IOException` catch boundaries.
- Preserved read unavailability, add/delete rollback, generic logs, localized
  errors, temporary-file cleanup, UTF-8 encoding, and same-directory writes.
- Moved the existence check inside the read boundary and made temporary-file
  existence/deletion permission-safe without duplicating cleanup logs.
- Added method-scoped contracts that reject missing or broad storage catches.
- Updated the user, security, vision, and change documentation.

## Verification Completed

- `make check` and external-working-directory baseline execution passed.
- Gradle lint, tests, and build truthfully skipped because no Android SDK is
  configured on this host.
- `sh -n scripts/check-baseline.sh` and `git diff --check` passed.
- Eight focused hostile mutations were rejected: missing read and write
  security catches, a broad read catch, lost read fail-closed state, an
  unguarded read existence check, missing cleanup security handling, stale plan
  status, and missing verification evidence.
- Exact-base generated-artifact and credential-shaped added-line scans passed.
- Hosted Android validation is recorded separately after push; this plan claims
  only the completed local SDK-free verification.
