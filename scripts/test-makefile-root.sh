#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE=$ROOT/Makefile
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-fridge-make-authority.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
CONTROL_DIR="$TEMP_ROOT/control dir"
SDK="$TEMP_ROOT/sdk dir"
mkdir -p "$CONTROL_DIR" "$SDK"
LOG="$TEMP_ROOT/commands.log"
FAKE_GRADLE="$TEMP_ROOT/gradle tool"
# shellcheck disable=SC2016
printf '%s\n' '#!/bin/sh' 'printf "gradle:%s\\n" "$*" >> "$ANDROID_FRIDGE_COMMAND_LOG"' > "$FAKE_GRADLE"
chmod +x "$FAKE_GRADLE"

require_text() {
  file=$1
  text=$2
  if ! grep -Fq "$text" "$ROOT/$file"; then
    printf '%s must document Make boundary: %s\n' "$file" "$text" >&2
    exit 1
  fi
}

: > "$LOG"
(cd "$CONTROL_DIR" && ANDROID_FRIDGE_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "ANDROID_HOME=$SDK" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/build.out"
grep -Fq 'gradle:assembleDebug --no-daemon' "$LOG"

for variable in ANDROID_HOME ANDROID_SDK_ROOT GRADLE; do
  if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" "$variable=\$(shell false)" build) > "$TEMP_ROOT/syntax.out" 2>&1; then exit 1; fi
  grep -Fq "$variable must be a literal value, not Make syntax" "$TEMP_ROOT/syntax.out"
done

STARTUP="$TEMP_ROOT/startup.mk"
STARTUP_MARKER="$TEMP_ROOT/startup-parse-marker"
printf '%s\n' "\$(shell /usr/bin/touch '$STARTUP_MARKER')" > "$STARTUP"
if (cd "$CONTROL_DIR" && MAKEFILES="$STARTUP" /usr/bin/make --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/startup.out" 2>&1; then exit 1; fi
grep -Eq 'repository Makefile path could not be resolved|MAKEFILES must be empty' "$TEMP_ROOT/startup.out"
[ -e "$STARTUP_MARKER" ]

LATER="$TEMP_ROOT/later.mk"
printf '%s\n' 'build:' '>@printf replaced' > "$LATER"
if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/later.out" 2>&1; then exit 1; fi

LATER_APPEND="$TEMP_ROOT/later-append.mk"
LATER_APPEND_MARKER="$TEMP_ROOT/later-append-marker"
printf 'build check lint root-test test verify: MAKEFILE_LIST := %s\n' "$MAKEFILE" > "$LATER_APPEND"
printf 'build::\n\t@/usr/bin/touch %s\n' "$LATER_APPEND_MARKER" >> "$LATER_APPEND"
(cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER_APPEND" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/later-append.out" 2>&1
[ -e "$LATER_APPEND_MARKER" ]

FAKE_SHELL="$TEMP_ROOT/fake-shell"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
cat > "$FAKE_SHELL" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >> "$ANDROID_FRIDGE_FAKE_SHELL_LOG"
printf '%s\n' ok
exit 0
SCRIPT
chmod +x "$FAKE_SHELL"
LATER_FAKE_SHELL="$TEMP_ROOT/later-fake-shell.mk"
printf 'build check lint root-test test verify: MAKEFILE_LIST := %s\n' "$MAKEFILE" > "$LATER_FAKE_SHELL"
printf 'build check lint root-test test verify: override SHELL := %s\n' "$FAKE_SHELL" >> "$LATER_FAKE_SHELL"
printf 'build check lint root-test test verify: override .SHELLFLAGS := -c\n' >> "$LATER_FAKE_SHELL"
(cd "$CONTROL_DIR" && ANDROID_FRIDGE_FAKE_SHELL_LOG="$FAKE_SHELL_LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER_FAKE_SHELL" check) > "$TEMP_ROOT/later-fake-shell.out" 2>&1
grep -Fq 'scripts/test-makefile-root.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/check-baseline.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/test-item-store.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/test-check-baseline.sh' "$FAKE_SHELL_LOG"
grep -Fq 'ok' "$TEMP_ROOT/later-fake-shell.out"

if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" MAKEFLAGS=-n "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/flags.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFLAGS must not be overridden' "$TEMP_ROOT/flags.out"

for flag in -n --just-print --dry-run --recon -t --touch -q --question -i --ignore-errors; do
  if (cd "$CONTROL_DIR" && /usr/bin/make "$flag" --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/mode.out" 2>&1; then exit 1; fi
  grep -Fq 'non-executing or error-ignoring MAKEFLAGS are not supported' "$TEMP_ROOT/mode.out"
done

require_text README.md 'Caller-supplied later makefiles, including target-specific SHELL/.SHELLFLAGS overrides and double-colon public recipes, are outside the local Make trust boundary.'
require_text docs/plans/2026-06-21-android-fridge-system-make-boundary.md 'Startup makefiles can run parse-time Make functions before the repository Makefile rejects them.'
require_text CHANGES.md 'Documented caller-supplied later makefiles and startup parse-time Make code as outside the local Make trust boundary.'

printf '%s\n' 'Make authority tests passed: external root, SDK and Gradle selection, 3 raw Make-syntax controls, startup parse-time boundary reproduction, later single-colon rejection, later double-colon append boundary reproduction, later fake-shell bypass boundary reproduction, caller MAKEFLAGS rejection, and 10 unsafe mode rejections'
