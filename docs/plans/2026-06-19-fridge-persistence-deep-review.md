---
title: Fridge Persistence Deep Review
date: 2026-06-19
status: completed
execution: code
---

# Fridge Persistence Deep Review

## Findings

The reviewed PR stack bounded aggregate file bytes and added backup-based
replacement, but reads still accepted malformed UTF-8 through replacement
decoding, a small file could create an excessive number of list rows, control
characters could survive persistence, and temporary output was renamed without
an explicit file-content sync. File type and symlink boundaries were also not
validated. The activity mutated and notified the live list before persistence
completed, exposing an avoidable transient UI state.

## Resolution

- Centralize path, decoding, validation, permission, sync, replacement, and
  recovery behavior in `ItemStore` and `ItemPolicy`.
- Keep the existing newline-delimited UTF-8 format while rejecting malformed or
  ambiguous records and bounding item count and size.
- Validate a backup before replacing a corrupt target and retain each previous
  target until the installed file is successfully read.
- Persist proposed list snapshots before committing them to the live model.
- Preserve historical baseline contracts and add host filesystem/concurrency,
  Android instrumentation, static policy, and hostile mutation tests.

## Residual risk

No physical API 21 tablet, flash filesystem fault injector, low-storage event,
or real process-death/power-loss sequence was available. Java 7 offers no
portable directory-fsync primitive, so the implementation syncs file contents
and retains a recoverable backup while device testing remains required for
rename metadata durability.
