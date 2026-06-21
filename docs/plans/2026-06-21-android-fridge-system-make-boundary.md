# Android Fridge System Make Boundary

Status: Completed

## Problem

Hosted and documented verification selected `make` through `PATH`. The
Makefile also allowed startup files, unsafe execution modes, later Makefiles,
shell changes, and target-specific SDK or Gradle values to redirect or suppress
the repository gate.

## Work Completed

- Bound GitHub Actions and contributor verification to `/usr/bin/make`.
- Froze `/bin/sh`, the canonical checkout root, Android SDK selection, and
  literal Gradle path across public targets.
- Rejected startup files, replaced Makefile lists, raw Make-syntax path values,
  later Makefiles, and non-executing or error-ignoring modes.
- Added `scripts/test-makefile-root.sh` to `/usr/bin/make check`.
- Extended the portable baseline and exact workflow contract.

## Verification

- Run `/usr/bin/make check` from the repository root.
- Run `/usr/bin/make -f <checkout>/Makefile check` externally.
- Run `scripts/test-makefile-root.sh` without an Android SDK.
- Let the hosted API 22/Java 8 job exercise the same boundary with Gradle.

## Scope Boundary

This change does not alter application behavior, persistence, dependencies,
permissions, or device data. Explicit literal SDK and Gradle paths remain
supported caller authority.
