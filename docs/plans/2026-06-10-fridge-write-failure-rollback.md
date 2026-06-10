# Fridge Write Failure Rollback

Status: Completed

## Context

Fridge list adds and removals changed the adapter before persistence, while
`writeItems()` only logged failures. If the atomic replacement failed, the
screen showed a list state that was not durable and would disappear or revert
after restart.

## Changes

- Return success from `writeItems()` only after the destination is replaced.
- Roll back failed additions by removing the newly inserted list entry while
  preserving the input text for retry.
- Roll back failed deletions by restoring the item at its original position.
- Notify the adapter after each rollback and show a localized, non-sensitive
  save error.
- Extend the SDK-free baseline with write-result and rollback contracts.

## Verification

- `make check`
- Static mutations for unconditional write success and removed rollback logic
- `git diff --check`

The Android SDK is unavailable on this host, so storage-failure UI behavior
still requires verification with a compatible Android toolchain.
