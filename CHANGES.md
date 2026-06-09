# Changes

## 2026-06-09

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
