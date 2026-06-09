# Fridge Date Header Guard

Date: 2026-06-09
Status: Completed

## Problem

`setupTime()` assumed the legacy `dateTime` header view always existed. Stale
tablet layouts or resource edits that omitted the header could crash startup
even though other optional view lookups were already guarded.

## Scope

- Guard the date header lookup before setting formatted text.
- Preserve the existing `M-d-yyyy` `Locale.US` display format.
- Extend the SDK-free baseline for the date header guard.

## Verification

- Red: `make lint` failed on the missing `if (dateTime != null)` source
  contract.
- Green: `make lint` passes after adding the guard.
- Full gate: `make check`.
