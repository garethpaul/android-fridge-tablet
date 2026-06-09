---
title: Fridge Keyboard Service Guard
type: reliability
status: completed
date: 2026-06-09
---

# Fridge Keyboard Service Guard

## Problem Frame

The activity requests focus for the item input and asks Android's input method
service to restart or hide the keyboard. `getSystemService()` can return null on
unusual tablet, test, or constrained runtime configurations, and the previous
code called keyboard methods unconditionally.

## Scope Boundaries

- Preserve the existing item-entry workflow and layout.
- Keep the app local-first and internal-storage backed.
- Do not add a new keyboard abstraction or dependency.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Guard Keyboard Service Calls

Files:

- Modify `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Approach:

- Check the `InputMethodManager` returned during startup before calling
  `restartInput`.
- Check the `InputMethodManager` returned after adding an item before calling
  `hideSoftInputFromWindow`.

### U2: Cover The Null-Safety Rule

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Add SDK-free source contracts for both input method manager guards.

### U3: Document The Guardrail

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record that keyboard service calls are optional and guarded.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
