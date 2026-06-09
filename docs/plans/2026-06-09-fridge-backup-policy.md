# Fridge Backup Policy

## Status: Completed

## Context

The Fridge app stores household item names in internal app storage and no longer
requests external storage permissions, but the manifest still allowed Android
backup. That could copy local fridge-list contents into platform backups by
default.

## Objectives

- Keep the app local-first and internal-storage-only.
- Disable Android backup for local fridge-list data.
- Add an SDK-free manifest contract so the backup setting is not accidentally
  reverted.

## Work Completed

- Set `android:allowBackup="false"` in the checked-in manifest.
- Extended `scripts/check-baseline.sh` to require backup-off and reject
  backup-on.
- Updated README, VISION, and CHANGES notes for the local data backup policy.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

Gradle lint, tests, and debug assembly run when `ANDROID_HOME` points to a
compatible Android SDK.
