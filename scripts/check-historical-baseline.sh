#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/MainActivity.java"
LAYOUT="$ROOT_DIR/app/src/main/res/layout/activity_main.xml"
README="$ROOT_DIR/README.md"
SECURITY="$ROOT_DIR/SECURITY.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEOWNERS="$ROOT_DIR/.github/CODEOWNERS"
READ_FAILURE_PLAN="$ROOT_DIR/docs/plans/2026-06-12-fridge-read-failure-write-guard.md"
STORAGE_LOG_PLAN="$ROOT_DIR/docs/plans/2026-06-13-fridge-storage-log-redaction.md"
SINGLE_LINE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-fridge-single-line-items.md"
STORAGE_SECURITY_PLAN="$ROOT_DIR/docs/plans/2026-06-13-fridge-storage-security-exceptions.md"
FILES_DIR_PLAN="$ROOT_DIR/docs/plans/2026-06-13-fridge-files-directory-unavailable.md"
DEVICE_VERIFICATION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-fridge-device-verification-checklist.md"
ATOMIC_REPLACEMENT_PLAN="$ROOT_DIR/docs/plans/2026-06-14-atomic-item-file-replacement.md"
ITEM_TRANSACTION="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemFileTransaction.java"
ITEM_TRANSACTION_TEST="$ROOT_DIR/app/src/test/java/garethpaul/com/fridge/ItemFileTransactionTest.java"
LIST_TRANSACTION="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java"
LIST_TRANSACTION_TEST="$ROOT_DIR/app/src/test/java/garethpaul/com/fridge/ItemListTransactionTest.java"
LIST_TRANSACTION_PLAN="$ROOT_DIR/docs/plans/2026-06-15-fridge-list-persistence-transaction-tests.md"
LIST_EXCEPTION_PLAN="$ROOT_DIR/docs/plans/2026-06-15-fridge-persistence-exception-rollback.md"
LAUNCHER_EXPORT_PLAN="$ROOT_DIR/docs/plans/2026-06-15-explicit-launcher-export.md"
APP_BUILD="$ROOT_DIR/app/build.gradle"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
HOSTED_ANDROID_PLAN="$ROOT_DIR/docs/plans/2026-06-12-hosted-android-verification.md"
WRAPPER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-gradle-wrapper-verification.md"
GRADLEW="$ROOT_DIR/gradlew"
GRADLEW_BAT="$ROOT_DIR/gradlew.bat"
WRAPPER_JAR="$ROOT_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPERTIES="$ROOT_DIR/gradle/wrapper/gradle-wrapper.properties"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf '%s\n' "A SHA-256 utility is required for wrapper verification." >&2
    exit 1
  fi
}

expected_wrapper_properties() {
  cat <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab
distributionUrl=https\://services.gradle.org/distributions/gradle-2.2.1-all.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
}

expected_ci_workflow() {
  cat <<'EOF'
name: Check

on:
  push:
    branches:
      - master
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true

concurrency:
  group: check-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    steps:
      - name: Check out repository
        uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
        with:
          persist-credentials: false

      - name: Install Android SDK packages
        run: '"${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-22" "build-tools;24.0.3"'

      - name: Set up Java 8
        uses: actions/setup-java@be666c2fcd27ec809703dec50e508c2fdc7f6654 # v5.2.0
        with:
          distribution: corretto
          java-version: "8"

      - name: Run full verification
        run: make check
EOF
}

require_contains() {
  file=$1
  pattern=$2
  message=$3

  if ! grep -Fq "$pattern" "$ROOT_DIR/$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_absent() {
  file=$1
  pattern=$2
  message=$3

  if grep -Fq "$pattern" "$ROOT_DIR/$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

for required_path in \
  "$ROOT_DIR/DEVICE_VERIFICATION.md" \
  "$DEVICE_VERIFICATION_PLAN"; do
  if [ ! -f "$required_path" ]; then
    printf '%s\n' "Required file is missing: ${required_path#"$ROOT_DIR/"}" >&2
    exit 1
  fi
done

for device_contract in \
  'commit SHA and pull request' \
  'Line separators in input' \
  'Unavailable files directory' \
  'Write or rename failure' \
  'Oversized existing file' \
  'Process recreation' \
  'Do not convert `not run` into passing evidence.' \
  'fridge items, canonical or temporary paths' \
  'every fridge device and storage row as' \
  'unexecuted'; do
  if ! grep -Fq "$device_contract" "$ROOT_DIR/DEVICE_VERIFICATION.md"; then
    printf '%s\n' "Fridge device checklist must keep contract: $device_contract" >&2
    exit 1
  fi
done

if ! grep -Fq 'DEVICE_VERIFICATION.md' "$README" || \
   ! grep -Fq 'explicit unexecuted rows' "$README" || \
   ! grep -Fqi 'Fridge device verification matrix' "$ROOT_DIR/VISION.md" || \
   ! grep -Fq 'every runtime row explicitly unexecuted' "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' 'Repository guidance must document the unexecuted Fridge device matrix.' >&2
  exit 1
fi

for plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No Android SDK, emulator, physical-tablet, or app-storage scenario was executed'; do
  if ! grep -Fq "$plan_contract" "$DEVICE_VERIFICATION_PLAN"; then
    printf '%s\n' "Fridge device plan must keep completion evidence: $plan_contract" >&2
    exit 1
  fi
done

require_contains "build.gradle" "url 'https://repo1.maven.org/maven2'" \
  "Build repositories must use HTTPS Maven Central."
require_absent "build.gradle" "jcenter()" \
  "Build repositories must not use JCenter."

require_contains "app/build.gradle" "apply plugin: 'com.android.application'" \
  "App module must apply com.android.application."
require_absent "app/build.gradle" "apply plugin: 'android'" \
  "App module must not apply the legacy android plugin."
require_contains "app/build.gradle" "compileSdkVersion 22" \
  "App module must compile with SDK 22."
require_contains "app/build.gradle" "buildToolsVersion \"24.0.3\"" \
  "App module must use build-tools 24.0.3."
require_contains "app/build.gradle" "targetSdkVersion 21" \
  "App module must preserve target SDK 21."
require_contains "app/build.gradle" "aaptOptions {" \
  "App module must configure deterministic legacy PNG processing."
require_contains "app/build.gradle" "useNewCruncher false" \
  "App module must avoid AGP 1.1's nondeterministic queued PNG cruncher."

require_absent "app/src/main/AndroidManifest.xml" \
  "android.permission.WRITE_EXTERNAL_STORAGE" \
  "Fridge app must not request external storage write permission."
require_absent "app/src/main/AndroidManifest.xml" \
  "android.permission.READ_EXTERNAL_STORAGE" \
  "Fridge app must not request external storage read permission."
require_contains "app/src/main/AndroidManifest.xml" \
  'android:allowBackup="false"' \
  "Fridge app must disable Android backups for local item storage."
require_absent "app/src/main/AndroidManifest.xml" \
  'android:allowBackup="true"' \
  "Fridge app must not allow Android backups."

MANIFEST="$ROOT_DIR/app/src/main/AndroidManifest.xml"
exported_count=$(awk '
  {
    line = $0
    while (match(line, /android:exported=/)) {
      count++
      line = substr(line, RSTART + RLENGTH)
    }
  }
  END { print count + 0 }
' "$MANIFEST")
if [ "$exported_count" -ne 1 ]; then
  printf '%s\n' "Fridge app must declare exactly one explicit component export boundary." >&2
  exit 1
fi
if ! awk '
  /<activity([[:space:]>]|$)/ {
    in_activity = 1
    name = 0
    exported = 0
    main_action = 0
    launcher_category = 0
  }
  in_activity && /android:name="\.MainActivity"/ { name = 1 }
  in_activity && /android:exported="true"/ { exported++ }
  in_activity && /android.intent.action.MAIN/ { main_action = 1 }
  in_activity && /android.intent.category.LAUNCHER/ { launcher_category = 1 }
  in_activity && /<\/activity>/ {
    if (name && exported == 1 && main_action && launcher_category) {
      valid_launcher++
    }
    in_activity = 0
  }
  END { exit !(valid_launcher == 1) }
' "$MANIFEST"; then
  printf '%s\n' "Fridge launcher activity must be explicitly exported with its MAIN/LAUNCHER filter." >&2
  exit 1
fi
require_absent "app/src/main/AndroidManifest.xml" \
  'android:exported="false"' \
  "Fridge launcher activity must remain externally reachable."

for launcher_export_document in \
  "$ROOT_DIR/AGENTS.md" "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "explicit launcher export boundary" "$launcher_export_document"; then
    printf '%s\n' "$launcher_export_document must document the explicit launcher export boundary." >&2
    exit 1
  fi
done
for launcher_export_plan_contract in \
  "status: completed" \
  'android:exported="true"' \
  'repository and external-directory `make check` passed' \
  "hostile mutations were rejected"; do
  if ! grep -Fq "$launcher_export_plan_contract" "$LAUNCHER_EXPORT_PLAN"; then
    printf '%s\n' "Fridge launcher export plan must preserve completion evidence: $launcher_export_plan_contract" >&2
    exit 1
  fi
done

if grep -Fq "today.month + \"-\"" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Date display must not use zero-based Time.month." >&2
  exit 1
fi


# Persistence contracts moved to scripts/check-baseline.sh and behavioral gates.

if ! grep -Fq "if (inputManager != null)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Keyboard restart must guard nullable InputMethodManager." >&2
  exit 1
fi

if ! grep -Fq "if (mgr != null)" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Keyboard hide must guard nullable InputMethodManager." >&2
  exit 1
fi

require_contains "README.md" "scripts/check-baseline.sh" \
  "README must document the SDK-free baseline check."
require_contains "README.md" "Android build-tools 24.0.3" \
  "README must document the pinned build-tools version."
require_contains "README.md" "target SDK 21" \
  "README must document the preserved target SDK."
require_contains "README.md" "date header uses one-based formatting" \
  "README must document the date-format baseline."
require_contains "README.md" "Fridge item storage uses UTF-8" \
  "README must document the fridge item file encoding."
require_contains "README.md" "missing item input view" \
  "README must document the fridge item input null guard."
require_contains "README.md" "missing list view" \
  "README must document the fridge list view null guard."
require_contains "README.md" "missing date header view" \
  "README must document the fridge date header null guard."
require_contains "README.md" "missing options menu" \
  "README must document the fridge menu callback null guard."
require_contains "README.md" "roll back the visible list" \
  "README must document fridge write-failure rollback."
require_contains "README.md" "unreadable existing item file" \
  "README must document fail-closed fridge read handling."

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
  exit 1
fi

require_contains "app/lint.xml" "LintError" \
  "lint.xml must document the obsolete lint API database limitation."
require_contains "app/lint.xml" "OldTargetApi" \
  "lint.xml must document the preserved target SDK baseline."
require_absent "app/src/main/res/values/strings.xml" "hello_world" \
  "Unused starter string must not be restored."
require_absent "app/src/main/res/values/dimens.xml" "activity_horizontal_margin" \
  "Unused horizontal margin dimen must not be restored."

if [ -f "$ROOT_DIR/app/src/main/res/values-w820dp/dimens.xml" ]; then
  printf '%s\n' "Unused w820dp dimen override must not be restored." >&2
  exit 1
fi

if grep -Fq "layout_alignParentRight" "$LAYOUT"; then
  printf '%s\n' "Layout must not use redundant right-alignment attributes." >&2
  exit 1
fi

if ! grep -Fq 'android:hint="@string/item_hint"' "$LAYOUT"; then
  printf '%s\n' "Item input must provide a hint." >&2
  exit 1
fi

if ! grep -Fq 'android:inputType="textCapSentences"' "$LAYOUT"; then
  printf '%s\n' "Item input must declare an inputType." >&2
  exit 1
fi

if grep -Eq 'android:text="[^@]' "$LAYOUT"; then
  printf '%s\n' "Layout text must use string resources." >&2
  exit 1
fi

if ! grep -Fq "./gradlew lint --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle lint verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew test --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle test verification." >&2
  exit 1
fi

if ! grep -Fq "./gradlew assembleDebug --no-daemon" "$README"; then
  printf '%s\n' "README must document Gradle build verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fridge-item-file-encoding.md"; then
  printf '%s\n' "Fridge item file encoding plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fridge-item-input-null-guard.md"; then
  printf '%s\n' "Fridge item input null guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fridge-list-view-guards.md"; then
  printf '%s\n' "Fridge list view guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fridge-date-header-guard.md"; then
  printf '%s\n' "Fridge date header guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fridge-menu-callback-guards.md"; then
  printf '%s\n' "Fridge menu callback guard plan must document make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-10-fridge-write-failure-rollback.md" || \
   ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-10-fridge-write-failure-rollback.md"; then
  printf '%s\n' "Fridge write-failure rollback plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$CI_WORKFLOW" ]; then
  printf '%s\n' "GitHub Actions check workflow is missing." >&2
  exit 1
fi

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
if [ "$workflow_paths" != "$CI_WORKFLOW" ]; then
  printf '%s\n' "check.yml must remain the only approved GitHub Actions workflow." >&2
  exit 1
fi

if [ "$(cat "$CI_WORKFLOW")" != "$(expected_ci_workflow)" ]; then
  printf '%s\n' "GitHub Actions check workflow must match the approved full Android security baseline." >&2
  exit 1
fi

if [ ! -f "$CI_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$CI_PLAN" || \
   ! grep -Fq "build-tools 24.0.3" "$CI_PLAN" || \
   ! grep -Fq 'complete `make check` gate' "$CI_PLAN"; then
  printf '%s\n' "Fridge CI baseline plan must document the complete hosted Android gate." >&2
  exit 1
fi

if [ ! -f "$HOSTED_ANDROID_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "make check" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "zero lint issues" "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq 'GitHub Actions `pull_request` run `27401692406` passed' "$HOSTED_ANDROID_PLAN" || \
   ! grep -Fq "e822f40bbf3dc505ba8e769de3245febe44e36ae" "$HOSTED_ANDROID_PLAN"; then
  printf '%s\n' "Hosted fridge verification plan must record completed local and hosted evidence." >&2
  exit 1
fi

if [ ! -x "$GRADLEW" ] || [ ! -f "$GRADLEW_BAT" ] || \
   [ ! -f "$WRAPPER_JAR" ] || [ ! -f "$WRAPPER_PROPERTIES" ]; then
  printf '%s\n' "Generated Gradle wrapper files must be present and gradlew must be executable." >&2
  exit 1
fi

if [ "$(cat "$WRAPPER_PROPERTIES")" != "$(expected_wrapper_properties)" ]; then
  printf '%s\n' "Gradle wrapper properties must retain the reviewed Gradle 2.2.1 URL and checksum." >&2
  exit 1
fi

if [ "$(sha256_file "$WRAPPER_JAR")" != "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172" ]; then
  printf '%s\n' "Gradle wrapper JAR must match Gradle's published 8.14.5 wrapper checksum." >&2
  exit 1
fi

if [ "$(sha256_file "$GRADLEW")" != "b187b4c52e749f5760afdd6fadc31b2a98ad35fb249bf0dff03b72650f320409" ] || \
   [ "$(sha256_file "$GRADLEW_BAT")" != "94102713eb8fb22d032397924c0f38ab2da783ba60d07054339f1190a0c4e2cd" ]; then
  printf '%s\n' "Gradle wrapper launchers must match the reviewed generated scripts." >&2
  exit 1
fi

if ! grep -Fq "Gradle start up script for POSIX generated by Gradle." "$GRADLEW" || \
   ! grep -Fq "Gradle startup script for Windows" "$GRADLEW_BAT"; then
  printf '%s\n' "Gradle wrapper launchers must retain generated provenance markers." >&2
  exit 1
fi

if [ ! -f "$WRAPPER_PLAN" ] || \
   ! grep -Fq "status: completed" "$WRAPPER_PLAN" || \
   ! grep -Fq "fresh temporary Gradle user home" "$WRAPPER_PLAN" || \
   ! grep -Fq "incorrect checksum was rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'SDK-backed `make check` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "external working directory" "$WRAPPER_PLAN" || \
   ! grep -Fq "hostile mutations rejected" "$WRAPPER_PLAN" || \
   ! grep -Fq 'pull-request `Check` run `27439707431` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq 'CodeQL run `27439705265` passed' "$WRAPPER_PLAN" || \
   ! grep -Fq "ee01ca37a8741893af96e1d582b3d9b02fc5e4e1" "$WRAPPER_PLAN"; then
  printf '%s\n' "Gradle wrapper plan must record completed local verification evidence." >&2
  exit 1
fi

if ! grep -Fq "distributionSha256Sum" "$README" || \
   ! grep -Fq "does not make the first build offline-reproducible" "$README" || \
   ! grep -Fq "wrapper JAR and Gradle distribution checksums" "$SECURITY"; then
  printf '%s\n' "Repository docs must describe wrapper verification and its online boundary." >&2
  exit 1
fi

if ! grep -Fq "canonical GitHub Actions workflow installs Android API 22" "$README" || \
   ! grep -Fq "2026-06-12-hosted-android-verification.md" "$README"; then
  printf '%s\n' "README must document the hosted Android gate and plan." >&2
  exit 1
fi

if [ ! -f "$SINGLE_LINE_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$SINGLE_LINE_PLAN" || \
   ! grep -Fq "make check" "$SINGLE_LINE_PLAN" || \
   ! grep -Fq "hostile mutations" "$SINGLE_LINE_PLAN"; then
  printf '%s\n' "Fridge single-line item plan must record completed verification." >&2
  exit 1
fi

for single_line_doc in "$ROOT_DIR/AGENTS.md" "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$single_line_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "line separators in fridge item input"; then
    printf '%s\n' "$single_line_doc must document the single-line persistence boundary." >&2
    exit 1
  fi
done

if [ ! -f "$STORAGE_SECURITY_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STORAGE_SECURITY_PLAN" || \
   ! grep -Fq "## Verification Completed" "$STORAGE_SECURITY_PLAN" || \
   ! grep -Fq "make check" "$STORAGE_SECURITY_PLAN" || \
   ! grep -Fq "Eight focused hostile mutations" "$STORAGE_SECURITY_PLAN" || \
   ! grep -Fq "generated-artifact and credential-shaped" "$STORAGE_SECURITY_PLAN"; then
  printf '%s\n' "Fridge storage security-exception plan must record completed verification." >&2
  exit 1
fi

for storage_security_doc in "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$storage_security_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "storage permission failures"; then
    printf '%s\n' "$storage_security_doc must document storage permission failures." >&2
    exit 1
  fi
done

if [ ! -f "$FILES_DIR_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$FILES_DIR_PLAN" || \
   ! grep -Fq "make check" "$FILES_DIR_PLAN" || \
   ! grep -Fq "hostile mutations" "$FILES_DIR_PLAN"; then
  printf '%s\n' "Fridge files-directory plan must record completed verification." >&2
  exit 1
fi
for files_dir_doc in "$ROOT_DIR/AGENTS.md" "$README" "$SECURITY" "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "unavailable app files directory" "$files_dir_doc"; then
    printf '%s\n' "$files_dir_doc must document unavailable app storage handling." >&2
    exit 1
  fi
done

if [ ! -f "$CODEOWNERS" ] ||
  [ "$(wc -l < "$CODEOWNERS" | tr -d ' ')" -ne 4 ] ||
  ! grep -Fxq '/.github/CODEOWNERS @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/.github/workflows/ @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/Makefile @garethpaul' "$CODEOWNERS" ||
  ! grep -Fxq '/scripts/check-baseline.sh @garethpaul' "$CODEOWNERS"; then
  printf '%s\n' "CODEOWNERS must protect itself, the workflow, Makefile, and baseline checker." >&2
  exit 1
fi

for make_contract in \
  'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_HOME ?=' \
  'ANDROID_SDK_ROOT ?=' \
  'GRADLE ?= $(ROOT)gradlew' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fxq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc '$(ROOT)scripts/check-baseline.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "Makefile lint must run the baseline checker from the protected root." >&2
  exit 1
fi
if [ "$(grep -Fc 'cd $(ROOT) && ANDROID_HOME=' "$ROOT_DIR/Makefile")" -ne 3 ]; then
  printf '%s\n' "All three Gradle gates must execute from the protected root." >&2
  exit 1
fi
for gradle_contract in '$(GRADLE) lint --no-daemon' '$(GRADLE) test --no-daemon' '$(GRADLE) assembleDebug --no-daemon'; do
  if [ "$(grep -Fc "$gradle_contract" "$ROOT_DIR/Makefile")" -ne 1 ]; then
    printf '%s\n' "Makefile must keep one rooted Gradle contract: $gradle_contract" >&2
    exit 1
  fi
done
if ! grep -Fxq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-14-android-fridge-make-root-override-protection.md"; then
  printf '%s\n' "Android fridge Make root protection plan must record completed status." >&2
  exit 1
fi

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi
