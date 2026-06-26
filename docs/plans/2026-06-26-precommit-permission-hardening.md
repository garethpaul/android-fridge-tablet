# Pre-Commit Permission Hardening

Status: Completed

## Context

`ItemStore.write()` installed the already-synced temporary file and then called
`hardenPermissions(target)`. If that final permission operation failed, the
method threw after durable contents had advanced. `ItemListTransaction` then
kept the old visible list because persistence reported failure, creating a
disk/UI divergence on the next reload.

## Design

- Keep owner-only permission hardening on `food.txt.tmp` before content is
  installed.
- Expose only the permission operation through a package-private test seam; keep
  the real file writer and replacement transaction in the regression.
- Return from `write()` immediately after `ItemFileTransaction` reports
  `INSTALLED`; do not perform another throwable target operation.
- Preserve read-time permission repair, backup verification, rollback,
  fsync, bounds, encoding, and app-private paths.

## Test First

The host regression requested a permission implementation that accepts
temporary-file hardening but throws if the installed `food.txt` is hardened.
The test failed to compile before the seam existed. With the old post-install
call retained, the same test would throw after the real replacement succeeds.

## Verification Plan

- Run the dependency-free host suite under `C` and `C.UTF-8` locales.
- Run `/usr/bin/make root-test`, `lint`, `test`, `build`, `verify`, and `check`.
- Run the canonical gate from `/tmp` through the absolute Makefile path.
- Run shell syntax checks and `git diff --check`.
- Reject isolated mutations that restore post-install hardening or remove the
  executable regression.
- Use hosted Android lint, tests, debug assembly, and CodeQL as exact-head
  authority when the local SDK is unavailable.

## Scope Boundaries

- No item format, policy, UI, backup lifecycle, rename state machine, logging,
  dependency, SDK, manifest, resource, or network change.
- Read-time hardening remains fail-closed because no UI model commit depends on
  it.

## Verification Completed

- The red-first `LC_ALL=C scripts/test-item-store.sh` invocation failed because
  the permission seam did not exist, then passed after implementation.
- `LC_ALL=C scripts/test-item-store.sh` and
  `LC_ALL=C.UTF-8 scripts/test-item-store.sh` passed.
- `/usr/bin/make root-test`, `lint`, `test`, `build`, `verify`, and `check`
  passed under both `C` and `C.UTF-8` locales.
- All six Make targets passed from `/tmp` through the absolute repository
  Makefile path.
- One follow-up external check initially referenced `$PWD` after changing into
  `/tmp` and therefore looked for `/tmp/Makefile`; rerunning with the repository
  path captured before `cd` passed.
- `scripts/check-baseline.sh` passed, and the 14-case hostile mutation suite
  passed, including rejection of restored post-install target hardening and a
  disabled executable regression.
- `sh -n` passed for the changed and canonical shell gates, and
  `git diff --check` passed.
- The local Android SDK was unavailable, so Gradle lint, unit tests, and debug
  assembly were explicitly skipped; hosted exact-head checks remain
  authoritative for those gates.
