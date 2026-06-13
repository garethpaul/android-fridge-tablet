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

if grep -Fq "today.month + \"-\"" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Date display must not use zero-based Time.month." >&2
  exit 1
fi

for pattern in \
  'private static final String LOG_TAG = "Fridge"' \
  'DISPLAY_DATE_PATTERN = "M-d-yyyy"' \
  "new SimpleDateFormat(DISPLAY_DATE_PATTERN, Locale.US).format(new Date())" \
  "getFilesDir()" \
  'private static final String ITEM_FILE_ENCODING = "UTF-8"' \
  'private static final String ITEM_TEMP_FILE_NAME = "food.txt.tmp"' \
  "FileUtils.readLines(" \
  "ITEM_FILE_ENCODING));" \
  "FileUtils.writeLines(temporaryFile, ITEM_FILE_ENCODING, items);" \
  "if (!temporaryFile.renameTo(todoFile))" \
  "temporaryFileRemoved = !temporaryFile.exists() || temporaryFile.delete();" \
  "catch (SecurityException e)" \
  "if (!temporaryFileRemoved)" \
  "String itemText = normalizedItemText(etNewItem);" \
  "if (itemText.length() == 0)" \
  "if (etNewItem != null)" \
  "if (lvItems != null)" \
  "if (lvItems == null)" \
  "if (dateTime != null)" \
  "if (pos < 0 || pos >= items.size())" \
  "if (menu == null)" \
  "if (item == null)" \
  "private String normalizedItemText(EditText itemInput)" \
  "if (itemInput == null || itemInput.getText() == null)" \
  "items.add(itemText);"; do
  if ! grep -Fq "$pattern" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Missing source baseline pattern: $pattern" >&2
    exit 1
  fi
done

NORMALIZED_ITEM_HELPER=$(sed -n \
  '/private String normalizedItemText(EditText itemInput)/,/^    }/p' \
  "$MAIN_ACTIVITY" | tr -d '\n\r\t')
for single_line_contract in \
  "if (itemInput == null || itemInput.getText() == null) {            return \"\";        }" \
  ".replace('\\r', ' ')" \
  ".replace('\\n', ' ')" \
  ".trim();"; do
  if ! printf '%s\n' "$NORMALIZED_ITEM_HELPER" | grep -Fq "$single_line_contract"; then
    printf '%s\n' "Fridge item normalization must keep contract: $single_line_contract" >&2
    exit 1
  fi
done

for write_result_contract in \
  "private boolean writeItems()" \
  "boolean written = false;" \
  "written = true;" \
  "return written;" \
  "if (!writeItems())" \
  "items.add(pos, removedItem);" \
  "items.remove(addedPosition);" \
  "showWriteError();"; do
  if ! grep -Fq "$write_result_contract" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Fridge write-result handling must keep contract: $write_result_contract" >&2
    exit 1
  fi
done

require_contains "app/src/main/res/values/strings.xml" \
  '<string name="write_items_error">Unable to save fridge items.</string>' \
  "Fridge write failures must use a localized user message."

if grep -Fq "FileUtils.writeLines(todoFile" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge persistence must not write directly to the destination file." >&2
  exit 1
fi

if grep -Fq "items.toString()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge item contents must not be logged." >&2
  exit 1
fi

if grep -Fq "Log.v(" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge item read path must not use verbose logging." >&2
  exit 1
fi

if grep -Fq "printStackTrace()" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge persistence errors must use sanitized Android logging." >&2
  exit 1
fi

require_contains "app/src/main/java/garethpaul/com/fridge/MainActivity.java" \
  'Log.w(LOG_TAG, "Unable to write fridge items");' \
  "Fridge write failures must log a sanitized warning."

for read_failure_contract in \
  "private boolean itemStorageAvailable;" \
  "if (!todoFile.exists())" \
  "itemStorageAvailable = true;" \
  "itemStorageAvailable = false;" \
  'Log.w(LOG_TAG, "Unable to read fridge items");' \
  "showReadError();" \
  "R.string.read_items_error"; do
  if ! grep -Fq "$read_failure_contract" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Fridge read-failure handling must keep contract: $read_failure_contract" >&2
    exit 1
  fi
done

READ_ITEMS_METHOD=$(sed -n '/private void readItems()/,/^    }/p' "$MAIN_ACTIVITY")
WRITE_ITEMS_METHOD=$(sed -n '/private boolean writeItems()/,/^    }/p' "$MAIN_ACTIVITY")
READ_ITEMS_COMPACT=$(printf '%s\n' "$READ_ITEMS_METHOD" | tr -d '[:space:]')
WRITE_ITEMS_COMPACT=$(printf '%s\n' "$WRITE_ITEMS_METHOD" | tr -d '[:space:]')

for storage_catch in "$READ_ITEMS_COMPACT" "$WRITE_ITEMS_COMPACT"; do
  for broad_catch in 'catch(RuntimeException' 'catch(Exception' 'catch(Throwable'; do
    if printf '%s\n' "$storage_catch" | grep -Fq "$broad_catch"; then
      printf '%s\n' "Fridge storage boundaries must not use broad catch: $broad_catch" >&2
      exit 1
    fi
  done

  if ! printf '%s\n' "$storage_catch" | \
      grep -Fq 'catch(IOException|SecurityExceptione)'; then
    printf '%s\n' "Fridge storage boundaries must handle IOException and SecurityException." >&2
    exit 1
  fi
done

for read_security_contract in \
  'try{if(!todoFile.exists())' \
  'itemStorageAvailable=false;' \
  'Log.w(LOG_TAG,"Unabletoreadfridgeitems");' \
  'showReadError();'; do
  if ! printf '%s\n' "$READ_ITEMS_COMPACT" | grep -Fq "$read_security_contract"; then
    printf '%s\n' "Fridge security read failures must keep contract: $read_security_contract" >&2
    exit 1
  fi
done

for write_security_contract in \
  'Log.w(LOG_TAG,"Unabletowritefridgeitems");' \
  'temporaryFileRemoved=!temporaryFile.exists()||temporaryFile.delete();' \
  'catch(SecurityExceptione){temporaryFileRemoved=false;}' \
  'if(!temporaryFileRemoved){Log.w(LOG_TAG,"Unabletoremovetemporaryfridgeitemfile");}' \
  'returnwritten;'; do
  if ! printf '%s\n' "$WRITE_ITEMS_COMPACT" | grep -Fq "$write_security_contract"; then
    printf '%s\n' "Fridge security write failures must keep contract: $write_security_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc 'Log.w(LOG_TAG,' "$MAIN_ACTIVITY" || true)" -ne 3 ]; then
  printf '%s\n' "Fridge storage must keep exactly three reviewed generic warnings." >&2
  exit 1
fi
for sensitive_storage_log in "getMessage()" "printStackTrace()" "Log.getStackTraceString" ", e);"; do
  if grep -Fq "$sensitive_storage_log" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Fridge storage logs must not include exception-derived details: $sensitive_storage_log" >&2
    exit 1
  fi
done
if [ ! -f "$STORAGE_LOG_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STORAGE_LOG_PLAN" || \
   ! grep -Fq "make check" "$STORAGE_LOG_PLAN" || \
   ! grep -Fq "hostile mutations" "$STORAGE_LOG_PLAN"; then
  printf '%s\n' "Fridge storage log-redaction plan must record completed verification." >&2
  exit 1
fi
for storage_doc in "$README" "$SECURITY" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$storage_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "generic fridge storage failure logs"; then
    printf '%s\n' "$storage_doc must document generic fridge storage failure logs." >&2
    exit 1
  fi
done

ADD_HANDLER=$(sed -n '/public void onAddItem(View v)/,/private String normalizedItemText/p' "$MAIN_ACTIVITY")
WRITE_HANDLER=$(sed -n '/private boolean writeItems()/,/private void showWriteError()/p' "$MAIN_ACTIVITY")

if ! printf '%s\n' "$ADD_HANDLER" | grep -Fq "if (!itemStorageAvailable)"; then
  printf '%s\n' "Fridge add path must reject unavailable item storage." >&2
  exit 1
fi

if ! printf '%s\n' "$WRITE_HANDLER" | grep -Fq "if (!itemStorageAvailable)"; then
  printf '%s\n' "Fridge write path must reject unavailable item storage." >&2
  exit 1
fi

require_contains "app/src/main/res/values/strings.xml" \
  '<string name="read_items_error">Unable to load fridge items. Changes are disabled.</string>' \
  "Fridge read failures must use a localized user message."

if [ ! -f "$READ_FAILURE_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$READ_FAILURE_PLAN" || \
   ! grep -Fq "make check" "$READ_FAILURE_PLAN"; then
  printf '%s\n' "Fridge read-failure write-guard plan must record completed make check verification." >&2
  exit 1
fi

if grep -Fq "String itemText = etNewItem.getText().toString();" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge items must not persist raw EditText text." >&2
  exit 1
fi

if grep -Fq "FileUtils.readLines(todoFile));" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge item reads must not use the platform default charset." >&2
  exit 1
fi

if grep -Fq "FileUtils.writeLines(todoFile, items);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Fridge item writes must not use the platform default charset." >&2
  exit 1
fi

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
  'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  'ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))'; do
  if ! grep -Fq "$make_contract" "$ROOT_DIR/Makefile"; then
    printf '%s\n' "Makefile must keep contract: $make_contract" >&2
    exit 1
  fi
done

if grep -Fq "/home/gjones" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must not embed a maintainer-specific Android SDK path." >&2
  exit 1
fi

printf '%s\n' "Fridge tablet baseline checks passed."
