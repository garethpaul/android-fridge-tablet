---
title: Fridge Item Input Normalization
type: reliability
status: completed
date: 2026-06-09
---

# Fridge Item Input Normalization

## Problem Frame

The fridge list add flow stores `EditText` content directly. Whitespace-only
entries can be persisted to the internal `food.txt` file, and leading or
trailing spaces become part of saved fridge items.

## Scope Boundaries

- Preserve the existing internal file storage path and `FileUtils.writeLines`
  persistence behavior.
- Do not change list deletion, date display, layout, Gradle, or target SDK
  behavior in this pass.
- Keep verification available through the SDK-free baseline script.

## Implementation Units

### U1: Normalize Item Text Before Add

Files:

- Modify `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Approach:

- Add a small `normalizedItemText(EditText itemInput)` helper.
- Trim input before validation.
- Skip item creation when the normalized value is empty.
- Add the normalized item text to the adapter and persisted list.

### U2: Extend Static Baseline Checks

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert that `onAddItem` uses the normalization helper.
- Assert that raw `EditText` text is not saved directly.
- Assert that empty normalized values return before persistence.

### U3: Document The Contract

Files:

- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- Record the input-normalization behavior and link this plan from maintenance
  notes.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

Gradle verification remains dependent on a compatible Android SDK.
