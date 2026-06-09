---
title: Fridge Log Privacy
type: security
status: completed
date: 2026-06-09
---

# Fridge Log Privacy

## Problem Frame

The fridge tablet app stores personal household list data locally. `readItems()`
logged the full stored item list with `items.toString()`, which can expose
household contents through Android logs during normal app startup.

## Scope Boundaries

- Preserve local internal-file storage and item input behavior.
- Do not add sync, encryption, backup policy changes, or storage migration in
  this pass.
- Keep verification available through the SDK-free baseline script.

## Implementation Units

### U1: Remove Item-Content Logging

Files:

- Modify `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Approach:

- Remove verbose read-path logs that expose item contents.
- Keep write failures visible with a generic `Log.w` message that does not
  include item values.
- Replace `printStackTrace()` with sanitized Android logging.

### U2: Extend Static Baseline Checks

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Reject `items.toString()` and verbose `Log.v` usage in `MainActivity`.
- Reject `printStackTrace()` in the persistence path.
- Require the sanitized write-failure log message.

### U3: Document The Privacy Contract

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record that fridge item contents stay out of diagnostic logs.
- Keep future storage, backup, or sync privacy work separate from this log
  hygiene pass.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
