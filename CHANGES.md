# Changes

## 2026-06-14

- Replaced platform-dependent direct item-file replacement with a tested
  backup/install/rollback transaction and startup backup recovery.
- Added a 1 MiB item-file limit before full-file parsing and before temporary
  output can replace the durable fridge list.
- Preflighted encoded fridge item size before opening temporary output while
  retaining the post-write check before durable replacement.
- Added an exact-commit Fridge tablet verification matrix for persistence,
  corruption, size limits, rollback, lifecycle, backup, and privacy-safe
  evidence, with every runtime row explicitly unexecuted.

## 2026-06-13

- Routed storage permission failures through the existing fail-closed read and
  rollback write paths without broad exception handling.
- Guarded an unavailable app files directory before read or write file
  construction, preserving fail-closed state and visible rollback.
- Normalized line separators in fridge item input so one submitted item remains
  one persisted list entry after reload.
- Replaced throwable-bearing read and write warnings with generic fridge
  storage failure logs and added regression contracts against exception-derived
  or additive storage logging.

## 2026-06-12

- Regenerated the Gradle wrapper bootstrap with official Gradle 8.14.5 tooling
  while retaining the Gradle 2.2.1 Android runtime.
- Pinned Gradle's official distribution checksum and added exact SDK-free
  contracts for the generated wrapper artifacts and documentation boundary.

## 2026-06-10

- Changed fridge-list persistence to write UTF-8 content to a same-directory
  temporary file before replacing the destination.
- Added write-result propagation so failed adds and removals roll back the
  visible list and show a localized warning.
- Made root checks location-independent, accepted `ANDROID_SDK_ROOT`, and
  pinned CI to Ubuntu 24.04 with superseded-run cancellation.
- Added a pinned, read-only GitHub Actions check workflow that runs the existing
  `make check` baseline with a bounded timeout and explicit SDK-free execution.
- Added an SDK-free guard requiring the CI workflow and completed CI baseline
  plan to remain checked in.
- Removed the maintainer-specific Android SDK path from the Makefile.
- Disabled persisted checkout credentials, added self-protecting CODEOWNERS,
  and replaced partial workflow checks with one canonical workflow contract.

## 2026-06-09

- Guarded options-menu callbacks when stale action-bar paths provide missing
  menu or menu item values.
- Guarded Fridge date header updates when stale tablet layouts omit the header
  view.
- Added SDK-free baseline coverage for the date header null guard.
- Guarded fridge list view setup and long-click removal positions so stale
  tablet layouts or callbacks do not crash the activity.
- Pinned fridge item file reads and writes to UTF-8 and added an SDK-free
  contract against platform-default charset persistence.
- Guarded Fridge keyboard service lookups before restarting or hiding input so
  tablet environments without an input method service do not crash the activity.
- Guarded item creation and keyboard setup when the legacy item input view is
  unavailable.
- Removed verbose logging of stored fridge item contents and added an SDK-free
  contract requiring sanitized persistence warnings.
- Disabled Android backup for the Fridge app and added a manifest contract so
  local fridge-list data is not backed up by default.

## 2026-06-08

- Added `make check` as the root wrapper for Fridge source, lint, test, and
  debug build verification.
- Added a repository changelog and expanded the documented Android verification
  gate to include lint, tests, and debug assembly.
- Cleaned Android lint findings by moving visible UI text into string
  resources, adding a hint and input type for the item field, and removing a
  redundant right-alignment attribute.
- Removed unused starter string and dimension resources and documented the
  narrow legacy lint baseline for the preserved target SDK.
- Removed unnecessary external storage permissions because fridge items are
  stored in the app's internal files directory.
- Trimmed fridge item input before persistence and ignored whitespace-only
  entries.
