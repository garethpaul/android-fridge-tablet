# Bound Fridge Item Storage Size

Status: Completed

## Context

The app reads the entire private `food.txt` file into memory on the UI thread.
The existing read-failure guard handles I/O and security exceptions, but an
unexpectedly large or corrupted file can allocate unbounded memory or stall
startup before either exception path can recover. The write path can also
replace the destination with output that the next launch will refuse to load
unless the same limit is enforced before rename.

## Scope

- Set a 1 MiB maximum for the encoded fridge item file.
- Reject an oversized existing destination before calling `FileUtils.readLines`.
- Reject oversized temporary output before atomic replacement, allowing the
  existing add/remove rollback paths to restore the visible list.
- Preserve UTF-8 encoding, single-line item normalization, atomic rename,
  temporary-file cleanup, generic logs, and localized errors.
- Add mutation-sensitive portable contracts and maintenance documentation.

## Implementation Units

### U1. Enforce the persistence limit

**Files:**

- `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Check the destination length before parsing. After writing the temporary file,
check its encoded length before rename so the durable destination never exceeds
the same limit through normal app writes.

### U2. Protect ordering and evidence

**Files:**

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-fridge-item-file-size-limit.md`

Require the fixed limit, read-before-parse ordering, write-before-rename
ordering, completed plan status, and verification evidence.

### U3. Document the boundary

**Files:**

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Document the fail-closed storage-size boundary and retained rollback behavior.

## Verification

Completed on 2026-06-14:

- Root and external-working-directory `make check` both passed the portable
  fridge baseline; Gradle lint, tests, and build were truthfully skipped because
  no Android SDK was configured.
- Six focused mutations were rejected when they removed either size check,
  moved checks after parsing or rename, weakened security documentation, or
  reopened this plan.

## Risks

- Existing item files over 1 MiB become unavailable rather than partially
  loaded; the localized read error remains the recovery signal.
- This change does not move file I/O off the UI thread or migrate the legacy
  line-oriented storage format.
