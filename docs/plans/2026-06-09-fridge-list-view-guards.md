# Fridge List View Guards

## Status: Completed

## Context

The activity already handles missing item input views, but the list setup path
still assumed the legacy tablet layout always includes `R.id.listView`. It also
trusted long-click callback positions before removing an item. Stale tablet
layouts or callbacks should not crash the activity.

## Objectives

- Preserve normal fridge item display and long-click removal.
- Avoid calling `setAdapter` or registering listeners on a missing list view.
- Ignore invalid long-click positions before mutating the item list.
- Keep the SDK-free baseline covering the guard.

## Work Completed

- Guarded `lvItems.setAdapter(...)` behind a null check.
- Returned early from `setupListViewListener()` when the list view is missing.
- Added a position range check before long-click item removal.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

## Follow-Up Candidates

- Add Android/JVM tests for list mutations once the legacy Gradle stack is
  modernized.
- Split the activity's item list behavior into a smaller presenter or helper
  before larger UI changes.
