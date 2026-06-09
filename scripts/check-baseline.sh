#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/MainActivity.java"
LAYOUT="$ROOT_DIR/app/src/main/res/layout/activity_main.xml"
README="$ROOT_DIR/README.md"

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
  "FileUtils.readLines(" \
  "ITEM_FILE_ENCODING));" \
  "FileUtils.writeLines(todoFile, ITEM_FILE_ENCODING, items);" \
  "String itemText = normalizedItemText(etNewItem);" \
  "if (itemText.length() == 0)" \
  "if (etNewItem != null)" \
  "private String normalizedItemText(EditText itemInput)" \
  "if (itemInput == null || itemInput.getText() == null)" \
  "return itemInput.getText().toString().trim();" \
  "itemsAdapter.add(itemText);"; do
  if ! grep -Fq "$pattern" "$MAIN_ACTIVITY"; then
    printf '%s\n' "Missing source baseline pattern: $pattern" >&2
    exit 1
  fi
done

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
  'Log.w(LOG_TAG, "Unable to write fridge items", e);' \
  "Fridge write failures must log a sanitized warning."

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

printf '%s\n' "Fridge tablet baseline checks passed."
