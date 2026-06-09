# Fridge Item Input Null Guard

## Status: Completed

## Context

Fridge item creation already trims text before persistence, but startup and
add-item paths still assumed the legacy `EditText` was always present. Layout
drift or stale tablet resources could crash before the existing empty-input
guard skipped item creation.

## Objectives

- Preserve item creation for valid non-empty input.
- Treat missing item input views or text values as empty item input.
- Avoid restarting keyboard input when the item input view is unavailable.
- Keep the SDK-free baseline covering the guard.

## Work Completed

- Guarded startup keyboard focus/restart against missing item input views.
- Added a null/text guard to `normalizedItemText()`.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add Android/JVM tests for item creation when the legacy Gradle stack is
  modernized.
- Replace activity-level view lookups with cached validated controls in a
  dedicated UI cleanup pass.
