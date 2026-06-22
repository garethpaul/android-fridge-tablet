# Android Fridge System Make Boundary

Status: Completed

## Problem

Hosted and documented verification selected `make` through `PATH`. The
Makefile also allowed startup files, unsafe execution modes, later Makefiles,
shell changes, and target-specific SDK or Gradle values to redirect or suppress
the repository gate.
Startup makefiles can run parse-time Make functions before the repository Makefile rejects them.

## Work Completed

- Bound GitHub Actions and contributor verification to `/usr/bin/make`.
- Froze `/bin/sh`, the canonical checkout root, Android SDK selection, and
  literal Gradle path across public targets.
- Rejected startup files, replaced Makefile lists, raw Make-syntax path values,
  later single-colon recipe replacement, and non-executing or error-ignoring
  modes for the checked-in Makefile path.
- Recorded caller-supplied later makefiles, target-specific shell overrides,
  double-colon public recipe appends, and startup parse-time Make code as
  outside the local Make trust boundary.
- Recorded that Make syntax in an explicit `-f` path is version-sensitive before the
  repository Makefile loads. GNU Make 3.81 and 4.2.1 execute Make syntax in an explicit `-f` path before the repository Makefile loads. Literal `$(` checkout paths must be invoked from inside the checkout without an explicit Makefile path.
- Added `scripts/test-makefile-root.sh` to `/usr/bin/make check`.
- Extended the portable baseline and exact workflow contract.

## Verification

- Run `/usr/bin/make check` from the repository root.
- Run `/usr/bin/make -f <checkout>/Makefile check` externally.
- Run `scripts/test-makefile-root.sh` without an Android SDK.
- Let the hosted API 22/Java 8 job exercise the same boundary with Gradle.
- Do not treat caller-supplied extra `-f` files or startup files as trusted
  validation; the harness reproduces those caller programs as outside-boundary
  cases.

## Scope Boundary

This change does not alter application behavior, persistence, dependencies,
permissions, or device data. Explicit literal SDK and Gradle paths remain
supported caller authority.
Caller-supplied later makefiles, including target-specific SHELL/.SHELLFLAGS overrides and double-colon public recipes, are outside the local Make trust boundary.
Hosted GitHub Actions remains authoritative because it invokes the checked-in
workflow command without caller-supplied extra makefiles or startup files.
