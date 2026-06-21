#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE=$ROOT/Makefile
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-fridge-make-authority.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
CONTROL_DIR="$TEMP_ROOT/control dir"
SDK="$TEMP_ROOT/sdk dir"
mkdir -p "$CONTROL_DIR" "$SDK"
LOG="$TEMP_ROOT/commands.log"
FAKE_GRADLE="$TEMP_ROOT/gradle tool"
printf '%s\n' '#!/bin/sh' 'printf "gradle:%s\\n" "$*" >> "$ANDROID_FRIDGE_COMMAND_LOG"' > "$FAKE_GRADLE"
chmod +x "$FAKE_GRADLE"

: > "$LOG"
(cd "$CONTROL_DIR" && ANDROID_FRIDGE_COMMAND_LOG="$LOG" /usr/bin/make --no-print-directory -f "$MAKEFILE" "ANDROID_HOME=$SDK" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/build.out"
grep -Fq 'gradle:assembleDebug --no-daemon' "$LOG"

for variable in ANDROID_HOME ANDROID_SDK_ROOT GRADLE; do
  if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" "$variable=\$(shell false)" build) > "$TEMP_ROOT/syntax.out" 2>&1; then exit 1; fi
  grep -Fq "$variable must be a literal value, not Make syntax" "$TEMP_ROOT/syntax.out"
done

STARTUP="$TEMP_ROOT/startup.mk"
printf '%s\n' '$(error startup file executed)' > "$STARTUP"
if (cd "$CONTROL_DIR" && MAKEFILES="$STARTUP" /usr/bin/make --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/startup.out" 2>&1; then exit 1; fi
grep -Eq 'startup file executed|MAKEFILES must be empty' "$TEMP_ROOT/startup.out"

LATER="$TEMP_ROOT/later.mk"
printf '%s\n' 'build:' '>@printf replaced' > "$LATER"
if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" -f "$LATER" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/later.out" 2>&1; then exit 1; fi

if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory -f "$MAKEFILE" MAKEFLAGS=-n "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/flags.out" 2>&1; then exit 1; fi
grep -Fq 'MAKEFLAGS must not be overridden' "$TEMP_ROOT/flags.out"

for flag in -n --just-print --dry-run --recon -t --touch -q --question -i --ignore-errors; do
  if (cd "$CONTROL_DIR" && /usr/bin/make "$flag" --no-print-directory -f "$MAKEFILE" "GRADLE=$FAKE_GRADLE" build) > "$TEMP_ROOT/mode.out" 2>&1; then exit 1; fi
  grep -Fq 'non-executing or error-ignoring MAKEFLAGS are not supported' "$TEMP_ROOT/mode.out"
done

printf '%s\n' 'Make authority tests passed: external root, SDK and Gradle selection, 3 raw Make-syntax controls, startup-file rejection, later Makefile rejection, caller MAKEFLAGS rejection, and 10 unsafe mode rejections'
