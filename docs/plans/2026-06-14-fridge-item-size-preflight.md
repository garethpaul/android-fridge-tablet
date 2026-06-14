# Fridge Item Size Preflight

Status: Completed

## Context

The fridge list rejects temporary output above 1 MiB, but checks the file only
after Commons IO has serialized the entire collection. A single oversized item
can therefore consume arbitrary app-private disk before the write is rejected
and rolled back.

## Scope

- Calculate the exact UTF-8 bytes Commons IO 2.0.1 will write for each item and
  platform line separator before opening the temporary output file.
- Reject collections above 1 MiB through the existing write-failure and visible
  rollback path.
- Retain the post-write size check, same-directory rename, cleanup, encoding,
  item ordering, generic logs, and localized errors.
- Add mutation-sensitive source, ordering, documentation, and plan contracts.

## Verification Plan

- Verify the vendored Commons IO bytecode writes each encoded item followed by
  `IOUtils.LINE_SEPARATOR` using the requested encoding.
- Run SDK-backed and external-working-directory `make check`.
- Reject isolated mutations that remove byte components, preflight invocation,
  ordering, post-write defense, documentation, or completed-plan evidence.
- Audit the exact diff, generated artifacts, conflict markers, whitespace, and
  credential-shaped additions before commit and push.

## Risks

- Preflight encoding allocates one item's UTF-8 byte array at a time; the 1 MiB
  disk boundary is enforced before output, but input-memory limits are outside
  this narrow change.
- Platform line-separator behavior and the existing Commons IO serialization
  format remain unchanged.

## Verification

Completed on 2026-06-14:

- `javap` against Commons IO 2.0.1 confirmed `writeLines` encodes each item and
  `IOUtils.LINE_SEPARATOR` with `ITEM_FILE_ENCODING` in the same order used by
  the preflight calculation.
- SDK-backed and external-working-directory `make check` passed.
- Seven isolated hostile mutations were rejected across item bytes, line
  separators, invocation, ordering, post-write defense, documentation, and
  completed-plan evidence.
- Exact-diff, generated-artifact, whitespace, conflict-marker, and
  credential-pattern audits passed before commit.
