---
title: Fridge Tablet Explicit Launcher Export Boundary
type: security
status: completed
date: 2026-06-15
---

# Fridge Tablet Explicit Launcher Export Boundary

## Problem Frame

The fridge tablet's `.MainActivity` owns the sole `MAIN`/`LAUNCHER` filter but
does not declare `android:exported`. Legacy Android therefore infers an
externally reachable activity. The implicit boundary is unclear to security
tooling and prevents a future Android 12 target upgrade without a manifest
correction.

## Priorities

1. P0: Preserve launcher behavior while explicitly declaring the existing
   component boundary.
2. P1: Add a mutation-sensitive structural contract that couples exactly one
   true export declaration to the named launcher activity and filter.
3. P1: Synchronize maintained guidance and completed evidence without changing
   persistence, list transactions, or tablet behavior.

## Requirements

- Set `android:exported="true"` only on `.MainActivity`.
- Preserve application metadata, backup policy, activity label and soft-input
  mode, launcher action/category, storage, persistence, and UI behavior.
- Reject missing, false, duplicate, unrelated, or filter-detached declarations.
- Keep repository and external-directory verification equivalent.
- Distinguish SDK-backed lint/build validation from unexecuted emulator,
  physical-tablet, and real storage-failure scenarios.

## Implementation Units

### 1. Declare launcher reachability

**File:** `app/src/main/AndroidManifest.xml`

Add the explicit true attribute to the existing launcher activity only.

### 2. Enforce structural ownership

**File:** `scripts/check-baseline.sh`

Count exported occurrences and require the sole declaration inside the
`.MainActivity` block containing the `MAIN` action and `LAUNCHER` category.

### 3. Synchronize durable guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Record the intentional boundary, validation, and remaining platform limits.

## Verification

- Run POSIX syntax and the focused baseline checker.
- Run repository and external-directory `make check` with Java 8 and the
  configured Android SDK.
- Reject missing, false, unrelated, filter-detached, same-line duplicate,
  missing-guidance, and incomplete-plan mutations.
- Audit generated artifacts, exact paths, file modes, whitespace, conflict
  markers, dependency/workflow drift, and credential-shaped additions.

## Risks And Mitigations

- **Launcher regression:** require the existing activity name and both filter
  entries alongside the exported declaration.
- **Overexposure:** allow exactly one exported occurrence and reject application
  or unrelated component declarations.
- **Legacy build:** retain all Gradle, Android plugin, SDK, and dependency
  versions.
- **Stacked delivery:** base this PR on persistence exception rollback and
  preserve base-first merge ordering.

## Out Of Scope

- Gradle, Android plugin, target/compile SDK, or dependency upgrades.
- New components, deep links, permissions, or intent filters.
- List transaction behavior, file replacement, backup recovery, encoding,
  storage limits, adapter reconciliation, or UI flows.

## Completion Evidence

- POSIX syntax and the focused Fridge baseline checker passed.
- repository and external-directory `make check` passed under Java 8 with the
  configured Android SDK; lint, debug/release unit tests, and debug assembly
  succeeded. Android lint reported zero issues for both variants.
- Seven isolated hostile mutations were rejected for missing, false,
  application-owned, filter-detached, same-line duplicate, missing-guidance,
  and incomplete-plan variants.
- The exact eight-path diff, generated-artifact cleanup, file modes,
  whitespace, conflict markers, dependency/workflow drift, and
  credential-shaped additions were audited before commit.
- No emulator, physical-tablet, or real storage-failure scenario was executed.
