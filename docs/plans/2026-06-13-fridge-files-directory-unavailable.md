# Fridge Files Directory Unavailable

Status: Planned

## Context

`readItems()` and `writeItems()` construct storage files immediately from
`getFilesDir()`. If Android cannot provide the app files directory, the current
code fails before its established read fail-closed state or write rollback
path can run.

## Requirements

- Treat a missing app files directory as a storage read failure during startup.
- Keep an empty in-memory list, mark storage unavailable, log generically, and
  show the existing localized read error.
- Return `false` from writes when the files directory is missing so existing
  add/remove rollback and localized write errors remain authoritative.
- Do not construct canonical or temporary files before the null guard.
- Preserve UTF-8 item encoding, atomic temporary replacement, permission/error
  handling, single-line normalization, and successful persistence behavior.
- Add mutation-sensitive static coverage, documentation, and truthful
  verification evidence.

## Implementation Units

### U1: Guard The Files Directory Boundary

**File:** `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Add method-local `filesDir == null` branches before either `File` constructor,
using the existing generic storage logs and read/write failure contracts.

### U2: Extend Portable Contracts

**File:** `scripts/check-baseline.sh`

Require both guards, method-local ordering, fail-closed read state, write false
return, generic logs, completed plan evidence, and guidance markers.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document unavailable app storage behavior. Run local and external `make check`,
hostile mutations, available Android verification, and final diff, artifact,
credential, and exact-head hosted checks.

## Scope Boundaries

- Do not add alternate storage roots, external storage, migration, retry, or
  recovery UI in this unit.
- Do not change item ordering, encoding, line normalization, atomic replacement,
  or rollback semantics.
- Do not claim emulator, physical-device, or forced files-directory failure
  behavior without those runtime facilities.

## Verification Plan

- Run `make check` locally and from an external working directory.
- Prove hostile mutations for missing read/write guards, post-construction
  guards, lost fail-closed state, non-false write result, reflected diagnostics,
  documentation drift, and incomplete-plan status fail.
- Run Android lint, Gradle tests, Java compilation, and debug assembly when the
  compatible SDK is available; otherwise record the local skip.
- Run `git diff --check`, generated-artifact inspection, and
  credential-shaped added-line scans.
- Record hosted evidence only after querying the exact pushed head.

## Verification

- Pending implementation.
