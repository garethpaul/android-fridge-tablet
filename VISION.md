## Android Fridge Tablet Vision

Android Fridge Tablet is a legacy Android tablet app for maintaining a simple
fridge list on-device.

The repository is useful as a preserved tablet-era Android app with a small data
entry workflow and explicit legacy build constraints. Project setup and
verification notes live in [`README.md`](README.md).

The goal is to keep the app recoverable and maintainable while making any
future revival safe for modern Android storage, dates, and device behavior.

The current focus is:

Priority:

- Preserve the documented Gradle, Android plugin, and SDK baseline
- Keep the on-device fridge-list workflow understandable
- Maintain SDK-free baseline verification
- Avoid hiding old toolchain requirements or local SDK assumptions

Next priorities:

- Modernize Gradle, target SDK, storage behavior, and date handling together
- Add tests around list item creation, persistence, and deletion flows
- Clarify emulator or tablet verification steps
- Reduce obsolete dependency assumptions when the app is actively revived

Contribution rules:

- One PR = one focused maintenance or app behavior topic.
- Run `scripts/check-baseline.sh` before pushing.
- Run the documented Gradle checks with a compatible Android SDK for code
  changes.
- Keep local SDK paths and generated files out of git.

## Security And Privacy

Fridge-list data is personal household data. Future sync, sharing, or backend
features need clear privacy notes and opt-in behavior.

The current app should remain local-first unless a separate design explains the
data flow, credentials, and user controls.

## What We Will Not Merge (For Now)

- Cloud sync or account features without privacy and configuration docs
- Broad Android modernization mixed with unrelated product changes
- Local machine paths, generated build artifacts, or signing material
- Changes that make the legacy project harder to verify from a fresh checkout
