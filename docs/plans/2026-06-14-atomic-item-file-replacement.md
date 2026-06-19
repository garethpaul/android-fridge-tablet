---
title: Atomic Fridge Item File Replacement
type: fix
status: completed
date: 2026-06-14
---

# Atomic Fridge Item File Replacement

## Problem Frame

The item writer creates a complete bounded temporary file, then calls
`temporaryFile.renameTo(todoFile)` while the prior item file may still exist.
Java does not guarantee replacement semantics for `File.renameTo`, and the
current path has no rollback transaction if installation fails. A platform
failure can therefore reject an otherwise valid save without a testable
last-known-good preservation contract.

## Requirements

- Preserve the existing item file as a same-directory backup until the new
  temporary file is installed.
- Restore the prior item file when installation fails.
- Keep both recoverable copies when rollback itself fails; never delete the
  backup in that path.
- Remove the backup after successful installation when possible. A cleanup
  failure must retain the stale backup without changing the successful save;
  the next write must clear it before touching the canonical file.
- Extract the replacement transaction from `MainActivity` into a package-private
  Java component with deterministic filesystem-operation injection.
- Add unit tests for first installation, successful replacement, installation
  failure with rollback, rollback failure, and stale-backup cleanup failure.
- Preserve the existing 1 MiB preflight, temporary-file cleanup, generic logs,
  UI error behavior, and API 21/Gradle 2.2.1 compatibility.

## Technical Design

`MainActivity` continues to encode and size-check the temporary file. It then
delegates replacement to `ItemFileTransaction`, which performs a three-step
same-directory transaction:

1. Remove any stale backup or fail before touching the current item file.
2. Move the current item file to the backup, then move the temporary file into
   the canonical path.
3. Delete the backup only after installation succeeds; on installation failure,
   move the backup back to the canonical path.

The component receives a minimal file-operations interface so unit tests can
force each failure boundary without Android or filesystem-specific races.

## Implementation Units

- **U1: Replacement transaction and unit tests**
  - Add `app/src/main/java/garethpaul/com/fridge/ItemFileTransaction.java`.
  - Add `app/src/test/java/garethpaul/com/fridge/ItemFileTransactionTest.java`.
  - Add the current JUnit 4 patch release as a test-only dependency.
- **U2: Activity integration and repository contracts**
  - Delegate the final temporary-file installation from `MainActivity`.
  - Extend `scripts/check-baseline.sh` with transaction, test, dependency, and
    completed-plan contracts.
  - Update `README.md`, `SECURITY.md`, `VISION.md`, and `CHANGES.md` with the
    preservation and non-device verification boundary.

## Verification

- Focused `ItemFileTransactionTest`, complete Gradle unit tasks, Android lint,
  debug assembly, repository `make check`, and external-directory `make check`.
- Hostile mutations for backup-before-install ordering, rollback, backup
  retention, cleanup failure, activity delegation, tests, and completed-plan
  evidence.
- Exact diff, generated-artifact, changed-line secret, and whitespace audits.
- One bounded exact-head hosted snapshot after push; no polling or wait loop.

## Risks

- Same-directory rename remains dependent on the app-private filesystem, but
  the transaction now has explicit rollback and deterministic failure tests.
- A rollback failure intentionally leaves the backup and temporary file for
  recovery rather than deleting the only remaining copies.
- No emulator storage corruption or lifecycle scenario is claimed by the unit
  suite; the checked-in device matrix remains the runtime boundary.

## Verification Results

- Eight focused `ItemFileTransactionTest` cases passed for first install,
  replacement, install rollback, rollback failure, stale backup refusal,
  cleanup failure, startup recovery, and failed startup recovery.
- Repository and external-directory `make check` passed, including SDK-backed
  lint, unit tests, debug assembly, and the portable contract checks.
- Ten hostile mutations were rejected across transaction ordering, rollback,
  recoverable-copy retention, activity delegation, tests, the pinned JUnit
  dependency, documentation, and completed-plan evidence.
- No emulator storage corruption or lifecycle scenario was executed, and no
  device persistence result is claimed.
