# Changes

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
