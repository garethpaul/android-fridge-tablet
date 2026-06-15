# Fridge List Persistence Transaction Tests

Status: Completed

## Context

`MainActivity` currently mutates the visible item list, calls `writeItems()`,
and manually reverses the mutation when persistence fails. The add and delete
paths are protected only by source-text contracts, so an ordering change can
leave the UI inconsistent with the last durable file without a behavioral unit
test failing. The repository vision explicitly prioritizes tests around item
creation, persistence, and deletion flows.

## Requirements

- **R1:** Keep add and delete list mutations consistent with the persistence
  result: retain successful changes and restore the exact prior order after a
  failed write.
- **R2:** Reject invalid delete positions without mutating the list or invoking
  persistence.
- **R3:** Extract the state transition into a package-private pure Java
  component with an injected persistence callback so it can be tested without
  Android or filesystem mocks.
- **R4:** Preserve input normalization, adapter refreshes, localized errors,
  item ordering, storage guards, and the existing file transaction.
- **R5:** Add mutation-sensitive portable contracts and truthful local,
  mutation, hosted, and Android-runtime evidence.

## Implementation Units

### U1: Pure List Transaction

**Files:**

- Create `app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java`.
- Create `app/src/test/java/garethpaul/com/fridge/ItemListTransactionTest.java`.

Model add and delete as synchronous transactions over the existing list. An
injected writer observes the mutated list and decides whether it commits. A
failed add removes only the appended entry; a failed delete restores the
removed entry at its original index. Invalid delete positions return an
explicit unchanged result without calling the writer.

Test successful and failed add, successful and failed delete at multiple
positions, exact-order rollback, and invalid positions.

### U2: Activity Integration

**File:** `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Route both item handlers through the pure transaction while keeping adapter
notifications and user-facing errors in the activity. Continue using the
existing `writeItems()` method as the persistence callback.

### U3: Contracts And Evidence

**Files:**

- Modify `scripts/check-baseline.sh`.
- Modify `README.md`.
- Modify `VISION.md`.
- Modify `CHANGES.md`.
- Modify this plan after verification.

Require the pure transaction, focused unit tests, activity delegation, and
completed evidence. Document that list rollback is behaviorally unit-tested
while Android view wiring remains a platform-runtime boundary.

## Test Scenarios

- Adding an item invokes persistence after mutation and retains it on success.
- A failed add restores the exact list that existed before the attempt.
- Deleting first, middle, and last entries retains the change on success.
- A failed delete restores the same item at the same index.
- Negative and end-exclusive delete positions leave the list unchanged and do
  not invoke persistence.
- Existing storage write failure still produces one adapter refresh after the
  final list state and the localized write error.

## Scope Boundaries

- Do not change item normalization, storage files, encoding, size limits,
  atomic replacement, logging, dependencies, Android/Gradle versions, or UI
  text.
- Do not add asynchronous persistence or claim emulator/tablet behavior from
  pure JVM tests.
- Keep this work stacked on the atomic replacement pull request.

## Completed Verification

- The focused `ItemListTransactionTest` passed all six cases through the pinned
  Gradle and Android plugin stack.
- Complete debug and release unit tasks passed, Android lint reported zero
  issues for both variants, and debug APK assembly succeeded with the installed
  Android SDK.
- The repository and external-directory `make check` gates passed with explicit
  SDK environment variables and bounded timeouts.
- Eight isolated hostile mutations were rejected for add rollback, delete
  rollback, invalid-position writer suppression, mutation/persistence ordering,
  activity delegation, test coverage, guidance, and plan status.
- Exact diff, whitespace, generated-artifact and likely-secret audits passed for
  the intended paths after removing only explicit reproducible build output.
- Hosted evidence is recorded separately from one bounded exact-head snapshot
  after push; no emulator or physical-tablet behavior is claimed by this plan.
