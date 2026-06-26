# Changes

## 2026-06-26 - P2 - Trim Unicode space around fridge items

- Replaced ASCII-only `String.trim()` input handling with code-point-aware
  leading and trailing Unicode-space trimming.
- Preserved internal emoji joiners, variation selectors, combining marks, and
  ordinary item spacing.
- Added a red-first host assertion for EM SPACE and NO-BREAK SPACE padding.

## 2026-06-26 11:35 - P2 - Reject standalone combining marks

### Summary
Rejected combining-mark-only fridge items that could create effectively blank
persisted rows while preserving decomposed text and keycap emoji with visible
base characters.

### Work completed
- Added Unicode mark-category handling to shared item visibility validation.
- Added red-first host regressions for standalone marks and positive coverage
  for marks attached to visible text and emoji bases.
- Extended static and hostile mutation contracts, repository guidance, and the
  completed implementation plan.

### Validation
- Red-first `LC_ALL=C ./scripts/test-item-store.sh` failed before implementation
  because standalone combining marks normalized successfully, then passed.
- All six documented Make aliases passed from the repository root and through
  the absolute Makefile path from `/tmp`; SDK-backed Gradle steps skipped
  because no Android SDK is configured locally.
- The host suite passed under `LC_ALL=C`, and 16 hostile static
  mutations passed before final syntax, diff, artifact, and credential audits.
- Hosted Gradle, CodeQL, exact-head review, and merge evidence remains the next
  action for this cycle.

### Bugs / findings
- P2: `ItemPolicy` counted ordinary Unicode mark categories as visible content,
  allowing a row made only from accents or enclosing marks.

### Blockers
- None for portable validation; Android SDK-backed checks may be skipped by the
  canonical Make gate when the SDK is unavailable.

### Next action
- Push the validated branch, review the immutable PR head, and merge only after
  hosted checks are green.

## 2026-06-26 02:26 - P1 - Keep write results aligned with durable contents

### Summary
Removed the throwable post-install permission step that could report a failed
write after the new fridge file was already installed, causing the UI model to
roll back while disk contents advanced.

### Work completed
- Added an injectable file-permission boundary for host regression coverage.
- Kept owner-only hardening on the same-directory temporary file before rename.
- Ended successful writes immediately after the replacement transaction reports
  `INSTALLED`.
- Added portable ordering contracts, hostile mutations, and maintenance docs.

### Threads
- Started: none.
- Continued: direct storage transaction audit — completed implementation and
  local regression coverage.
- Stopped: none.

### Files changed
- `app/src/main/java/garethpaul/com/fridge/ItemStore.java` — makes permission
  operations injectable and removes post-install hardening.
- `scripts/host-tests/garethpaul/com/fridge/ItemStoreHostTest.java` — proves a
  successful installed write is not followed by target permission mutation.
- `scripts/check-baseline.sh` and `scripts/test-check-baseline.sh` — enforce and
  mutation-test the ordering invariant.
- Documentation and plan files — record the transactional boundary.

### Validation
- Red-first `LC_ALL=C scripts/test-item-store.sh` — failed because the permission
  seam did not exist, then passed after implementation.
- `LC_ALL=C` and `LC_ALL=C.UTF-8` host suites — passed.
- `/usr/bin/make root-test|lint|test|build|verify|check` under both locales —
  passed; local SDK-backed Gradle steps were explicitly skipped.
- The same six Make targets from `/tmp` via the absolute Makefile path — passed.
- One follow-up external check used `$PWD` after `cd /tmp` and failed to find
  `/tmp/Makefile`; the corrected captured-path invocation passed.
- Fourteen hostile static mutations, shell syntax checks, and
  `git diff --check` — passed.
- Hosted Gradle, CodeQL, exact-head review, and merge evidence remains the next
  action for this cycle.

### Bugs / findings
- P1: `ItemStore.write()` could throw from `hardenPermissions(target)` after
  durable installation, making `ItemListTransaction` preserve the old visible
  model even though the new file was already on disk.

### Blockers
- None for portable validation; local Android SDK availability is checked by the
  canonical Make gate.

### Next action
- Run the full local and hosted exact-head validation matrix, then review and
  merge the focused PR.

## 2026-06-25

- Made the dependency-free item-store host test compile its Unicode fixtures
  with an explicit UTF-8 source encoding instead of inheriting the host locale.
- Rejected Unicode invisible-only fridge items at both input and stored-file
  validation boundaries while preserving visible joined emoji.

## 2026-06-21

- Bound hosted and contributor verification to `/usr/bin/make` and added an
  executable authority harness covering shell, root, SDK, Gradle,
  single-colon recipe replacement, and unsafe-mode boundaries.
- Documented caller-supplied later makefiles and startup parse-time Make code as outside the local Make trust boundary.
- Documented version-specific explicit `-f` Make-syntax paths as pre-load caller authority.
- Covered GNU Make 4.2.1's explicit `-f` pre-load behavior in the portable authority regression harness.

## 2026-06-19

- Replaced permissive whole-file persistence with a strict UTF-8 item store
  that bounds item count, per-item bytes, aggregate bytes, and control content.
- Rejected symlinked or non-regular storage files, hardened owner-only file
  permissions, synced temporary content before replacement, and validated
  backups before corruption recovery.
- Changed UI list transactions to persist a proposed snapshot before committing
  it to the adapter-owned model, with serialized mutation ownership.
- Added host filesystem, concurrency, instrumentation, static-policy, and
  hostile mutation tests; removed the unused legacy Commons IO dependency.

## 2026-06-15

- Added an explicit launcher export boundary for the sole `MAIN`/`LAUNCHER`
  activity and a structural manifest contract.

## 2026-06-15

- Persistence exceptions restore the exact fridge list before propagation.
- Added behavioral list transaction tests for successful and failed item
  creation and deletion, including exact-order rollback and invalid positions.
- Routed the activity's add/delete persistence transitions through the tested
  pure Java transaction without changing storage or UI error behavior.

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
