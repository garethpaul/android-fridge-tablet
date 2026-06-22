# AGENTS.md

## Repository purpose

`garethpaul/android-fridge-tablet` is an Android application or sample. The App for my fridge.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `app` - application source or app module
- `build.gradle` - Gradle build configuration
- `gradlew` - checked-in Gradle wrapper

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `/usr/bin/make check`
- Combined verification: `/usr/bin/make verify`
- Lint/static checks: `/usr/bin/make lint`
- Tests: `/usr/bin/make test`
- Build: `/usr/bin/make build`
- Android unit tests when the SDK is configured: `./gradlew test`
- Android debug build when the SDK is configured: `./gradlew assembleDebug`
- Run the Make aliases as documented, without caller-supplied extra `-f` files
  or `MAKEFILES`, when collecting repository validation evidence.
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Java (2), shell (1).
- Use the checked-in Gradle wrapper for Android builds when an SDK is configured.

## Testing guidance

- No dedicated test files were detected; treat `/usr/bin/make check` as the minimum baseline.
- Start with the narrowest relevant test or Make target, then run `/usr/bin/make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.
- Caller-supplied later makefiles, including target-specific SHELL/.SHELLFLAGS overrides and double-colon public recipes, are outside the local Make trust boundary.
- Startup makefiles can run parse-time Make functions before the repository
  Makefile rejects them.
- Make syntax in an explicit `-f` path is version-sensitive before the repository Makefile loads; GNU Make 3.81 and 4.2.1 execute that syntax before loading the repository Makefile. Use the checkout as the working directory for paths containing literal `$(`.
- Keep the explicit launcher export boundary on `.MainActivity`, which owns the
  sole `MAIN`/`LAUNCHER` filter; do not export unrelated components.
- This legacy Android baseline pins Android build-tools 24.0.3 and preserves target SDK 21.
- Fridge items are stored in the app's internal files directory, so the app does not request external storage permissions.
- An unavailable app files directory must be rejected before constructing
  canonical or temporary storage files.
- Fridge item input is trimmed before persistence, and whitespace-only entries are ignored.
- Persistence exceptions restore the exact fridge list before propagation.
- Line separators in fridge item input are converted to spaces so one submitted
  item remains one persisted item after reload.
- A missing item input view is treated as empty input so stale tablet layouts do not crash item creation or keyboard setup.
- A missing list view skips list wiring, and stale long-click positions are ignored before item removal.
- If an existing fridge-item file cannot be read, storage becomes unavailable,
  the UI reports the localized error, and add/write paths fail closed rather
  than replacing unreadable data.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `/usr/bin/make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
