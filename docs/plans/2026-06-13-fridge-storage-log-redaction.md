# Fridge Storage Log Redaction

Status: Completed

## Context

Fridge read and write failures display localized generic UI errors and preserve
fail-closed or rollback behavior, but both catch paths pass the caught
`IOException` to logcat. Throwable messages and stacks can expose the app's
internal file path and filesystem details without improving user recovery.

## Requirements

- Log stable read and write failure categories without caught throwables.
- Keep internal file paths, exception messages, and stacks out of storage logs.
- Preserve read-failure storage unavailability, atomic temporary writes,
  temporary-file cleanup, list rollback, localized toasts, and UTF-8 behavior.
- Strengthen SDK-free contracts against throwable and additive storage logs.
- Update privacy guidance and completed verification evidence.

## Implementation

- Replace the two throwable-bearing storage warnings in `MainActivity.java`.
- Require exact fixed categories and total storage-log count in
  `scripts/check-baseline.sh`.
- Update README, SECURITY, CHANGES, and this plan.

## Verification

- `scripts/check-baseline.sh` passed with exact fixed read, write, and cleanup
  warning contracts.
- `ruby /tmp/engineering-bar/test-android-fridge-storage-log-mutations.rb`
  rejected eight hostile mutations covering throwable restoration, exception
  messages, stack conversion, additive logging, cleanup-category removal,
  documentation drift, and plan removal.
- `make check` passed with Java 8 and the configured Android SDK, including
  Android lint, unit tests, and debug assembly.
