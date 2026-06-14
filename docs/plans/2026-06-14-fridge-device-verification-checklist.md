# Fridge Device Verification Checklist

Status: In Progress

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

- Pending implementation and bounded repository validation.
