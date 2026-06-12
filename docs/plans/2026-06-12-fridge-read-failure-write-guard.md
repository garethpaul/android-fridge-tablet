# Fridge Read Failure Write Guard

Status: Completed

## Context

`readItems` currently converts every `IOException` into an empty list. A
missing file is a normal first-launch state, but an existing file that cannot
be read may still contain durable fridge items. Treating that failure as an
empty writable list allows the next add operation to replace data the app
failed to load.

## Changes

- Treat a missing item file as an available, empty first-launch state.
- Mark item storage unavailable when an existing file cannot be read.
- Log a sanitized read warning and show a localized user-facing error.
- Reject add and write paths while storage is unavailable so unread data is not
  overwritten.
- Extend the SDK-free baseline and README with the fail-closed read contract.

## Verification

- `make check`
- Static mutations for removing the existing-file check, add guard, and write
  guard
- `git diff --check`

The Android SDK is unavailable on this host, so device storage and Toast
behavior still require verification with a compatible Android toolchain.
