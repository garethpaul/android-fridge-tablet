# Fridge Device Verification Checklist

Status: Completed

## Problem

Portable contracts cover app-private storage, atomic writes, rollback, size
limits, single-line items, unavailable directories, and redacted errors, but no
checklist defines emulator/device evidence for real filesystem behavior.

## Requirements

1. Add an exact-commit matrix for build, empty state, persistence, corruption,
   size limits, failure rollback, lifecycle, backup, and privacy behavior.
2. Require sanitized toolchain, emulator/device, result, and storage evidence.
3. Keep repository checks separate from unexecuted Android storage scenarios.
4. Add mutation-sensitive contracts for the checklist and completion evidence.

## Scope Boundaries

- Do not modernize Gradle, Android APIs, target SDK, or dependencies.
- Do not add fridge contents, storage files, APKs, logs, backups, or keys.
- Do not claim emulator or physical-device execution from portable checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- `sh -n scripts/check-baseline.sh` and the focused Fridge baseline checker
  passed.
- Repository-root and external-working-directory `make check` passed all
  portable contracts and retained the existing bounded SDK behavior.
- Twelve hostile mutations were rejected for removing checklist, persistence,
  corruption, size, rollback, lifecycle, privacy, unexecuted-result,
  documentation, or completed-plan evidence.
- No Android SDK, emulator, physical-tablet, or app-storage scenario was executed; every runtime matrix row remains `not run`.
