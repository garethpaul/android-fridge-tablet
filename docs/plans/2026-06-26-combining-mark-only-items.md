# Reject Combining-Mark-Only Fridge Items

## Status: Completed

## Goal

Prevent effectively blank fridge rows made only from Unicode combining marks
without rejecting valid marks attached to visible text or emoji bases.

## Implementation

- Added a shared Unicode mark-category check to visible-content detection.
- Added red-first host coverage for standalone non-spacing and enclosing marks.
- Added positive coverage for decomposed text and keycap emoji.
- Extended the baseline and mutation contracts.
- Updated repository guidance and the cycle change log.

## Verification Completed

- Red-first `LC_ALL=C ./scripts/test-item-store.sh` failed before the policy
  change because combining-mark-only input normalized successfully.
- The focused host suite passed after implementation.
- All six repository Make aliases passed from the repository root and through
  the absolute Makefile path from `/tmp`; SDK-backed Gradle steps skipped
  because no Android SDK is configured locally.
- 16 hostile static mutations passed.
- Shell syntax, diff, artifact, and credential audits passed before push.
