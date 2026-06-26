## Android Fridge Tablet Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Android Fridge Tablet is a legacy Android tablet app for maintaining a simple
fridge list on-device.

The repository is useful as a preserved tablet-era Android app with a small data
entry workflow and explicit legacy build constraints. Project setup and
verification notes live in [`README.md`](README.md).

The goal is to keep the app recoverable and maintainable while making any
future revival safe for modern Android storage, dates, and device behavior.

The current focus is:

Priority:

- Keep the explicit launcher export boundary limited to `.MainActivity` and
  keep unrelated Android components private
- Preserve the documented Gradle, Android plugin, and SDK baseline
- Keep the on-device fridge-list workflow understandable
- Maintain SDK-free baseline verification
- Keep fridge item creation from persisting empty-looking entries
- Keep line separators in fridge item input from changing item boundaries after
  reload
- Keep visible fridge items consistent with successful durable writes
- Finish throwable permission hardening before durable installation so write
  results cannot diverge from installed contents
- Keep item creation safe when legacy input views are missing
- Keep list view setup safe when stale tablet layouts omit the list view
- Keep date header updates safe when stale tablet layouts omit the header
- Keep menu callbacks guarded when stale action-bar paths pass missing values
- Keep local item file encoding explicit across device defaults
- Keep storage permission failures inside fail-closed read and rollback write
  boundaries
- Fail closed when Android reports an unavailable app files directory
- Replace fridge-list contents through a temporary file instead of truncating
  the destination during writes
- Preserve and restore the last-known-good item file across replacement
  failures, retaining recoverable copies if rollback itself fails
- Keep optional tablet input services guarded before keyboard operations
- Keep personal fridge-list contents out of diagnostic logs
- Keep local fridge-list contents out of Android backups by default
- Bound encoded fridge item storage to 1 MiB before parsing or replacement
- Preflight encoded fridge item storage before temporary-file writes
- Keep GitHub Actions running the root `/usr/bin/make check` baseline before review
- Keep the legacy Gradle runtime behind a checksum-verified generated wrapper
- Avoid hiding old toolchain requirements or local SDK assumptions
- Keep exact-commit tablet storage evidence separate from portable contracts,
  with unexecuted persistence and corruption scenarios recorded explicitly
- Test list creation, deletion, and persistence rollback as pure Java state transitions
- Persistence exceptions restore the exact fridge list before propagation.

Next priorities:

- Evaluate Gradle runtime, SDK, plugin, storage, and date modernization together
  in a dedicated compatibility pass; wrapper bootstrap hardening is separate
- Clarify emulator or tablet verification steps
- Reduce obsolete dependency assumptions when the app is actively revived
- Execute the Fridge device verification matrix with synthetic household data
  and privacy-safe evidence

Contribution rules:

- One PR = one focused maintenance or app behavior topic.
- Run `scripts/check-baseline.sh` before pushing.
- Keep `.github/workflows/check.yml` aligned with the documented `/usr/bin/make check`
  wrapper.
- Run the documented Gradle checks with a compatible Android SDK for code
  changes.
- Keep local SDK paths and generated files out of git.

## Security And Privacy

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Fridge-list data is personal household data. Future sync, sharing, or backend
features need clear privacy notes and opt-in behavior.

The current app should remain local-first unless a separate design explains the
data flow, credentials, and user controls.
Fridge entries should retain Unicode-visible item content while rejecting
separator-, format-, or default-ignorable-mark-only rows that render as blank
list entries.

## What We Will Not Merge (For Now)

- Cloud sync or account features without privacy and configuration docs
- Broad Android modernization mixed with unrelated product changes
- Local machine paths, generated build artifacts, or signing material
- Changes that make the legacy project harder to verify from a fresh checkout

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
