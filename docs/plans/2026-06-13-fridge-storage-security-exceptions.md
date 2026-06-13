# Handle Fridge Storage Security Exceptions

Status: Planned

## Context

The fridge persistence boundaries fail closed for `IOException`, but Android
file access can also throw `SecurityException`. Those failures currently escape
the activity instead of using the existing unavailable-state or rollback paths.

## Requirements

- R1. Read-time `SecurityException` failures must mark storage unavailable,
  preserve the empty in-memory list, use the generic read log, and show the
  localized read error.
- R2. Write-time `SecurityException` failures must return `false`, retain
  temporary-file cleanup, and use the generic write log so callers preserve
  their existing add/delete rollback behavior.
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
