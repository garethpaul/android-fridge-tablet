---
title: Fridge Internal Storage Permissions
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# Fridge Internal Storage Permissions

## Problem Frame

The app requests read and write external storage permissions, but its item
persistence uses `getFilesDir()` and writes `food.txt` inside the app's internal
files directory. The manifest can avoid asking for permissions that the current
behavior does not need.

## Scope Boundaries

- Preserve the existing internal `food.txt` persistence behavior.
- Do not migrate storage APIs, target SDK, Gradle, or UI structure.
- Keep verification SDK-free for this pass.

## Implementation Units

### U1: Manifest Permission Cleanup

Files:

- `app/src/main/AndroidManifest.xml`

Approach:

- Remove `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE`.

### U2: Baseline Contracts And Docs

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `CHANGES.md`

Approach:

- Require the permissions to stay absent.
- Require the source to keep using `getFilesDir()`.
- Document the internal-storage baseline.

## Verification

- `scripts/check-baseline.sh`
- `git diff --check`
