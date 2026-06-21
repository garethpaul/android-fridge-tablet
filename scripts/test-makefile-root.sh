#!/bin/sh
set -eu

SCRIPT_DIR=$(dirname -- "$0")
case $SCRIPT_DIR in
  /*) ROOT=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd -P) ;;
  *) ROOT=$(CDPATH='' cd "./$SCRIPT_DIR/.." && pwd -P) ;;
esac
MAKEFILE=$ROOT/Makefile
MAKE_BIN=${MAKE_BIN:-/usr/bin/make}
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

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

run_in_control_success() {
  output=$1
  shift
  set +e
  (cd "$CONTROL_DIR" && "$@") > "$output" 2>&1
  status=$?
  set -e
  if [ "$status" -ne 0 ]; then
    printf 'Expected command to succeed, exited %s: %s\n' "$status" "$*" >&2
    cat "$output" >&2
    exit "$status"
  fi
}

run_in_control_failure() {
  output=$1
  shift
  set +e
  (cd "$CONTROL_DIR" && "$@") > "$output" 2>&1
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    printf 'Expected command to fail, but it succeeded: %s\n' "$*" >&2
    cat "$output" >&2
    exit 1
  fi
}

require_text() {
  file=$1
  text=$2
  if ! grep -Fq "$text" "$ROOT/$file"; then
    fail "$file must document Make boundary: $text"
  fi
}

CD_DASH_DASH=$(printf 'cd %s' --)
if grep -Fq "$CD_DASH_DASH" \
  "$MAKEFILE" \
  "$ROOT/scripts/check-baseline.sh" \
  "$ROOT/scripts/check-historical-baseline.sh" \
  "$ROOT/scripts/test-check-baseline.sh" \
  "$ROOT/scripts/test-item-store.sh" \
  "$ROOT/scripts/test-makefile-root.sh"; then
  fail 'Repository shell entrypoints must not rely on non-POSIX cd double-dash handling.'
fi

: > "$LOG"
run_in_control_success "$TEMP_ROOT/build.out" env ANDROID_FRIDGE_COMMAND_LOG="$LOG" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" "ANDROID_HOME=$SDK" "GRADLE=$FAKE_GRADLE" build
grep -Fq 'gradle:assembleDebug --no-daemon' "$LOG"

for variable in ANDROID_HOME ANDROID_SDK_ROOT GRADLE; do
  run_in_control_failure "$TEMP_ROOT/syntax.out" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" "$variable=\$(shell false)" build
  grep -Fq "$variable must be a literal value, not Make syntax" "$TEMP_ROOT/syntax.out"
done

STARTUP="$TEMP_ROOT/startup.mk"
STARTUP_MARKER="$TEMP_ROOT/startup-parse-marker"
printf '%s\n' "\$(shell /usr/bin/touch '$STARTUP_MARKER')" > "$STARTUP"
run_in_control_failure "$TEMP_ROOT/startup.out" env MAKEFILES="$STARTUP" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build
grep -Eq 'repository Makefile path could not be resolved|MAKEFILES must be empty' "$TEMP_ROOT/startup.out"
[ -e "$STARTUP_MARKER" ]

LATER="$TEMP_ROOT/later.mk"
printf '%s\n' 'build:' '>@printf replaced' > "$LATER"
run_in_control_failure "$TEMP_ROOT/later.out" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" -f "$LATER" "GRADLE=$FAKE_GRADLE" build

LATER_APPEND="$TEMP_ROOT/later-append.mk"
LATER_APPEND_MARKER="$TEMP_ROOT/later-append-marker"
printf 'build check lint root-test test verify: MAKEFILE_LIST := %s\n' "$MAKEFILE" > "$LATER_APPEND"
printf 'build::\n\t@/usr/bin/touch %s\n' "$LATER_APPEND_MARKER" >> "$LATER_APPEND"
run_in_control_success "$TEMP_ROOT/later-append.out" env ANDROID_FRIDGE_COMMAND_LOG="$LOG" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" -f "$LATER_APPEND" "ANDROID_HOME=$SDK" "GRADLE=$FAKE_GRADLE" build
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
run_in_control_success "$TEMP_ROOT/later-fake-shell.out" env ANDROID_FRIDGE_COMMAND_LOG="$LOG" ANDROID_FRIDGE_FAKE_SHELL_LOG="$FAKE_SHELL_LOG" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" -f "$LATER_FAKE_SHELL" "ANDROID_HOME=$SDK" "GRADLE=$FAKE_GRADLE" check
grep -Fq 'scripts/test-makefile-root.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/check-baseline.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/test-item-store.sh' "$FAKE_SHELL_LOG"
grep -Fq 'scripts/test-check-baseline.sh' "$FAKE_SHELL_LOG"
grep -Fq 'ok' "$TEMP_ROOT/later-fake-shell.out"

run_in_control_failure "$TEMP_ROOT/flags.out" "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" MAKEFLAGS=-n "GRADLE=$FAKE_GRADLE" build
grep -Fq 'MAKEFLAGS must not be overridden' "$TEMP_ROOT/flags.out"

for flag in -n --just-print --dry-run --recon -t --touch -q --question -i --ignore-errors; do
  run_in_control_failure "$TEMP_ROOT/mode.out" "$MAKE_BIN" "$flag" --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build
  grep -Fq 'non-executing or error-ignoring MAKEFLAGS are not supported' "$TEMP_ROOT/mode.out"
done

require_text README.md 'Caller-supplied later makefiles, including target-specific SHELL/.SHELLFLAGS overrides and double-colon public recipes, are outside the local Make trust boundary.'
require_text docs/plans/2026-06-21-android-fridge-system-make-boundary.md 'Startup makefiles can run parse-time Make functions before the repository Makefile rejects them.'
require_text CHANGES.md 'Documented caller-supplied later makefiles and startup parse-time Make code as outside the local Make trust boundary.'

printf '%s\n' 'Make authority tests passed: external root, SDK and Gradle selection, 3 raw Make-syntax controls, startup parse-time boundary reproduction, later single-colon rejection, later double-colon append boundary reproduction, later fake-shell bypass boundary reproduction, caller MAKEFLAGS rejection, and 10 unsafe mode rejections'
