---
title: Gradle Wrapper Verification
date: 2026-06-12
status: completed
execution: code
---

# Gradle Wrapper Verification

## Summary

Introduce a checksum-capable generated Gradle Wrapper bootstrap while
preserving the fridge app's characterized Gradle 2.2.1 and Java 8 Android
runtime. Add the repository's first static wrapper provenance contract and
verify the unchanged API 22 build locally and on the final pull-request head.

## Problem Frame

The repository already has a complete source, lint, unit-test, and debug-build
gate, but its 2013-era wrapper downloads Gradle 2.2.1 without verifying the
archive and the SDK-free baseline does not authenticate the checked-in wrapper
JAR or launchers. Updating the Android runtime at the same time would combine a
supply-chain fix with a broader compatibility migration.

## Requirements

- **R1:** Continue executing `gradle-2.2.1-all.zip` under Java 8 without
  changing Android Gradle Plugin 1.1.0, compile SDK 22, target SDK 21,
  build-tools 24.0.3, dependencies, repositories, or app behavior.
- **R2:** Pin Gradle's official Gradle 2.2.1 all-distribution SHA-256,
  `1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab`.
- **R3:** Regenerate `gradlew`, `gradlew.bat`, and `gradle-wrapper.jar` with
  official Gradle 8.14.5 tooling and verify the published wrapper JAR SHA-256,
  `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`.
- **R4:** Extend the dependency-free baseline to reject wrapper URL,
  checksum, JAR, launcher, documentation, and completion-evidence drift.
- **R5:** Pass the complete Java 8/API 22 `make check` gate locally and on the
  final pull-request head before tracker reconciliation.

## Key Technical Decisions

- **Separate bootstrap from runtime:** use Gradle 8.14.5 only to generate the
  wrapper files while retaining the Gradle 2.2.1 runtime required by the
  existing Android plugin.
- **Verify both downloaded and checked-in artifacts:** use
  `distributionSha256Sum` at bootstrap time and exact SDK-free hashes for the
  wrapper JAR and generated launchers.
- **Keep online availability explicit:** checksums authenticate expected bytes
  but an uncached first build still depends on Gradle's HTTPS distribution
  service.
- **Preserve the all distribution:** avoid changing IDE and source archive
  availability in a security-only migration.

## Scope Boundaries

### In Scope

- The four Gradle Wrapper files.
- Wrapper provenance and completed-evidence contracts in
  `scripts/check-baseline.sh`.
- Wrapper guidance in `README.md`, `SECURITY.md`, `VISION.md`, and `CHANGES.md`.
- Local and hosted compatibility evidence.

### Deferred

- Gradle runtime, Android plugin, SDK targets, dependencies, and app code.
- UI, storage, lifecycle, and persistence behavior.
- Applying the migration to other repositories before this exact head is
  locally and remotely verified.

## Implementation Units

### U1. Verified Wrapper Bootstrap

**Goal:** Authenticate the downloaded Gradle runtime without changing it.

**Requirements:** R1, R2, R3

**Files:**

- `gradlew`
- `gradlew.bat`
- `gradle/wrapper/gradle-wrapper.jar`
- `gradle/wrapper/gradle-wrapper.properties`

**Verification:** A fresh Java 8 Gradle user home launches Gradle 2.2.1, an
incorrect checksum fails before execution, and the wrapper JAR matches Gradle's
published 8.14.5 checksum.

### U2. Static Contract And Documentation

**Goal:** Make wrapper provenance and its online dependency durable repository
contracts.

**Requirements:** R3, R4

**Files:**

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-12-gradle-wrapper-verification.md`

**Verification:** Focused mutations to properties, JAR, launchers,
documentation, and plan evidence are rejected by the SDK-free checker.

### U3. Compatibility And Hosted Evidence

**Goal:** Prove the wrapper change preserves the complete Android build.

**Requirements:** R1, R5

**Files:**

- `docs/plans/2026-06-12-gradle-wrapper-verification.md`

**Verification:** `make check` passes from the repository and an external
working directory, then the final pull-request and CodeQL checks pass at the
exact pushed head.

## Risks And Mitigations

- **Cached downloads hide verification:** use a fresh temporary Gradle user
  home for positive and negative bootstrap tests.
- **Generated bootstrap is incompatible with Java 8:** verify `./gradlew
  --version` under Java 8 before project tasks; the official wrapper classes
  remain Java 6 bytecode compatible.
- **Scope expands into Android modernization:** reject build-file or app-code
  changes in this unit.

## Sources

- [Gradle Wrapper documentation](https://docs.gradle.org/current/userguide/gradle_wrapper.html)
- [Gradle security best practices](https://docs.gradle.org/current/userguide/best_practices_security.html)
- [Gradle 2.2.1 all-distribution checksum](https://services.gradle.org/distributions/gradle-2.2.1-all.zip.sha256)
- [Gradle 8.14.5 wrapper JAR checksum](https://services.gradle.org/distributions/gradle-8.14.5-wrapper.jar.sha256)

## Work Completed

- Regenerated all four wrapper files with official Gradle 8.14.5 tooling while
  retaining the Gradle 2.2.1 all distribution and existing Android runtime.
- Added the official distribution checksum and the repository's first exact
  wrapper JAR, launcher, properties, documentation, and plan contracts.
- Documented the authenticated-download boundary without changing build files
  or app behavior.

## Verification Completed

- A fresh temporary Gradle user home downloaded the official distribution and
  reported Gradle 2.2.1 on Corretto Java 8 (`1.8.0_482`).
- A disposable wrapper with an incorrect checksum was rejected before Gradle
  execution and reported the official archive checksum.
- SDK-backed `make check` passed with zero lint findings, both unit-test
  variants, and debug assembly under Java 8/API 22 from the repository and an
  external working directory.
- Focused hostile mutations rejected wrapper properties, JAR, launcher,
  documentation, and incomplete plan evidence.
- `sh -n scripts/check-baseline.sh` and `git diff --check` passed.

## Hosted Verification

- On implementation head `ee01ca37a8741893af96e1d582b3d9b02fc5e4e1`,
  pull-request `Check` run `27439707431` passed the full Java 8/API 22 gate.
- CodeQL run `27439705265` passed both the actions and java-kotlin analyzers on
  the same implementation head.
- PR #2 was open, clean, and mergeable at that head. The final evidence-only
  commit must rerun the same pull-request and CodeQL gates before tracker
  reconciliation.
