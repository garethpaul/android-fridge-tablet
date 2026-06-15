---
title: Fridge Persistence Exception Rollback
type: reliability
status: in_progress
date: 2026-06-15
---

# Fridge Persistence Exception Rollback

## Problem Frame

`ItemListTransaction` rolls back optimistic add and remove mutations when its
`Persistence` callback returns `false`, but not when that callback throws an
unchecked exception. The exception escapes with the in-memory list still
mutated, violating the transaction's state-restoration guarantee and making a
later UI recovery observe uncommitted state.

## Priorities

1. **P0: Roll back before rethrow.** Restore the exact list state for add and
   remove operations when persistence throws a runtime exception, then rethrow
   the original instance.
2. **P1 follow-up: Device verification.** Exercise write failures and tablet UI
   recovery through the checked-in device matrix.
3. **P2 follow-up: Storage modernization.** Coordinate dependency, SDK, and
   storage API changes in a separate compatibility pass.

This plan implements only P0.

## Requirements

- Preserve normal committed and `false`-return rollback behavior.
- On add exceptions, remove exactly the newly appended item before rethrowing.
- On remove exceptions, restore the removed item at its original position
  before rethrowing.
- Preserve the original runtime exception instance and do not convert or
  suppress it.
- Preserve invalid-position writer suppression, MainActivity notifications,
  localized errors, item normalization, and file replacement behavior.
- Add mutation-sensitive source, behavioral-test, documentation, and
  completed-plan contracts.

## Implementation Units

### 1. Make list mutations exception-safe

**Files:** `app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java`

Wrap each persistence call so its corresponding optimistic mutation is undone
before the original runtime exception is rethrown.

### 2. Prove exact restoration and exception identity

**Files:**
`app/src/test/java/garethpaul/com/fridge/ItemListTransactionTest.java`,
`scripts/check-baseline.sh`

Add add/remove exception fixtures that assert exact list contents and ordering,
the same exception object, and one persistence attempt. Extend the portable
checker so removal or weakening of these guarantees fails closed.

### 3. Synchronize maintained guidance

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `AGENTS.md`, `CHANGES.md`

Document that unchecked persistence failures restore list state before
propagation.

## Verification

- Run the focused pure-Java transaction test and configured Gradle unit gates.
- Run Android lint/build when the compatible SDK is available.
- Run `make check` from the repository root and an external directory.
- Run isolated hostile mutations for add rollback, remove position, exception
  identity, documentation, and plan completion.
- Audit exact intended paths, generated artifacts, conflict markers,
  whitespace, dependency drift, and credential-shaped additions.

## Completion Evidence

Pending implementation and validation.

## Risks And Mitigations

- **Exception masking:** perform only deterministic list restoration in the
  catch block and rethrow the captured exception object unchanged.
- **Ordering regression:** restore removals with `add(position, removedItem)`
  and assert edge/middle ordering in tests.
- **Stacked delivery:** base the pull request on PR #12 and retain base-first
  ordering.

## Out Of Scope

- Swallowing persistence exceptions or converting them to `false`.
- Changing file formats, atomic replacement, size limits, Android UI flows,
  dependencies, Gradle, SDK levels, or device behavior.
