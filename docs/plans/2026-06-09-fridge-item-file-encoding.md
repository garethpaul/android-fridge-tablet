---
title: Fridge Item File Encoding
type: reliability
status: completed
date: 2026-06-09
---

# Fridge Item File Encoding

## Problem Frame

The fridge list persisted item text through Commons IO default-charset
overloads. That made saved item bytes depend on the device/runtime default
encoding instead of a stable app contract.

## Scope Boundaries

- Preserve the existing local `food.txt` file and internal storage location.
- Keep the current add, delete, and normalization behavior.
- Do not change the data format beyond making the charset explicit.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Pin The Item File Charset

Files:

- Modify `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Approach:

- Add a named `UTF-8` encoding constant for item persistence.
- Use the explicit-encoding Commons IO read overload.
- Use the explicit-encoding Commons IO write overload.

### U2: Cover And Document The Contract

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Add SDK-free checks that reject default-charset read/write overloads.
- Document the UTF-8 persistence contract in project notes.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
