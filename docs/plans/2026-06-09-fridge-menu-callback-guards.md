# Fridge Menu Callback Guards

Date: 2026-06-09
Status: Completed

## Problem

The Fridge activity guarded several stale-layout view paths, but the options
menu callbacks still assumed Android always supplied non-null menu and menu
item objects. Test harnesses, stale action-bar paths, or unusual lifecycle
dispatch could crash before the callback had anything useful to handle.

## Scope

- Preserve the existing settings menu inflation and selection behavior.
- Return without handling when menu callback inputs are missing.
- Do not redesign or remove the legacy options menu.
- Keep verification available through the SDK-free baseline check.

## Work Completed

- Added a null guard to `onCreateOptionsMenu(Menu menu)` before menu inflation.
- Added a null guard to `onOptionsItemSelected(MenuItem item)` before reading
  the selected item id.
- Extended the SDK-free baseline and project documentation for the callback
  guard.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
