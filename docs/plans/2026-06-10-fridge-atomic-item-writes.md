# Fridge Atomic Item Writes

Status: Completed

## Goal

Avoid truncating the only fridge-list file when persistence is interrupted or
fails partway through a write.

## Requirements

- Serialize items as UTF-8 to a same-directory temporary file.
- Replace the destination only after the temporary write succeeds.
- Preserve the existing destination when replacement fails.
- Remove stale temporary files without logging fridge-list contents or paths.
- The SDK-free baseline rejects direct destination writes.
- Root Make targets work outside the checkout and accept either Android SDK
  environment variable.
- Hosted verification uses a fixed runner and cancels superseded runs.

## Implementation

- Add a fixed internal temporary filename beside `food.txt`.
- Write through `FileUtils.writeLines`, then use `File.renameTo` for the
  same-directory replacement.
- Clean up the temporary file in `finally` with a constant warning.
- Extend `scripts/check-baseline.sh` with persistence, rooted `Makefile`, and CI
  contracts.
- Pin GitHub Actions to Ubuntu 24.04 and add workflow concurrency.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- persistence and automation mutation checks
- shell syntax checks
- `git diff --check`

The Android SDK is not available on this host, so runtime filesystem behavior
still requires verification with the legacy-compatible toolchain.
