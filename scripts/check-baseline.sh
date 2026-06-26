#!/bin/sh
set -eu

SCRIPT_DIR=$(dirname -- "$0")
case $SCRIPT_DIR in
  /*) ROOT_DIR=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd) ;;
  *) ROOT_DIR=$(CDPATH='' cd "./$SCRIPT_DIR/.." && pwd) ;;
esac
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/MainActivity.java"
ITEM_POLICY="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
ITEM_STORE="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemStore.java"
LIST_TRANSACTION="$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java"
HOST_STORAGE_TEST="$ROOT_DIR/scripts/host-tests/garethpaul/com/fridge/ItemStoreHostTest.java"
MANIFEST="$ROOT_DIR/app/src/main/AndroidManifest.xml"
WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
WRAPPER_JAR="$ROOT_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPERTIES="$ROOT_DIR/gradle/wrapper/gradle-wrapper.properties"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

require_literal() {
  file=$1
  literal=$2
  message=$3
  grep -Fq "$literal" "$file" || fail "$message"
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

require_literal "$ROOT_DIR/app/build.gradle" 'compileSdkVersion 22' 'Compile SDK baseline changed.'
require_literal "$ROOT_DIR/app/build.gradle" 'targetSdkVersion 21' 'Target SDK baseline changed.'
require_literal "$MANIFEST" 'android:allowBackup="false"' 'Fridge data backup must remain disabled.'
require_literal "$MANIFEST" 'android:exported="true"' 'Launcher export boundary must remain explicit.'

exported_count=$(grep -Fc 'android:exported=' "$MANIFEST")
[ "$exported_count" -eq 1 ] || fail 'Only the launcher activity may declare an exported component.'
require_literal "$MANIFEST" 'android.intent.action.MAIN' 'Launcher MAIN action missing.'
require_literal "$MANIFEST" 'android.intent.category.LAUNCHER' 'Launcher category missing.'

require_literal "$ITEM_POLICY" 'MAX_FILE_BYTES = 1024L * 1024L' 'Aggregate item-file limit missing.'
require_literal "$ITEM_POLICY" 'MAX_ITEM_BYTES = 4096' 'Per-item byte limit missing.'
require_literal "$ITEM_POLICY" 'MAX_ITEMS = 512' 'Item-count limit missing.'
require_literal "$ITEM_POLICY" 'Character.isISOControl(codePoint)' 'Control-character rejection missing.'
require_literal "$ITEM_POLICY" 'Character.isWhitespace(codePoint)' 'Unicode whitespace visibility rejection missing.'
require_literal "$ITEM_POLICY" 'Character.isSpaceChar(codePoint)' 'Unicode separator visibility rejection missing.'
require_literal "$ITEM_POLICY" 'Character.getType(codePoint) == Character.FORMAT' 'Unicode format-only visibility rejection missing.'
require_literal "$ITEM_POLICY" 'codePoint == 0x034F' 'Combining grapheme joiner visibility rejection missing.'
require_literal "$ITEM_POLICY" 'codePoint >= 0x180B && codePoint <= 0x180D' 'Mongolian variation-selector visibility rejection missing.'
require_literal "$ITEM_POLICY" 'codePoint >= 0xFE00 && codePoint <= 0xFE0F' 'Variation-selector visibility rejection missing.'
require_literal "$ITEM_POLICY" 'codePoint >= 0xE0100 && codePoint <= 0xE01EF' 'Supplementary variation-selector visibility rejection missing.'
require_literal "$ITEM_POLICY" 'Character.NON_SPACING_MARK' 'Non-spacing mark-only visibility rejection missing.'
require_literal "$ITEM_POLICY" 'Character.COMBINING_SPACING_MARK' 'Combining-spacing mark-only visibility rejection missing.'
require_literal "$ITEM_POLICY" 'Character.ENCLOSING_MARK' 'Enclosing mark-only visibility rejection missing.'
require_literal "$ITEM_POLICY" '!isCombiningMark(codePoint)' 'Combining-mark visibility guard is not applied.'
require_literal "$ITEM_POLICY" 'if (!hasVisibleContent)' 'Invisible-only item rejection missing.'
require_literal "$ITEM_POLICY" 'CodingErrorAction.REPORT' 'Strict item encoding validation missing.'
require_literal "$HOST_STORAGE_TEST" 'rejectsUnicodeInvisibleOnlyItems' 'Invisible-only item host regression missing.'
require_literal "$HOST_STORAGE_TEST" 'test.rejectsCombiningMarkOnlyItems();' 'Combining-mark-only item host regression missing.'
require_literal "$HOST_STORAGE_TEST" 'preservesVisibleJoinedEmojiItems' 'Joined emoji visibility regression missing.'

require_literal "$ITEM_STORE" 'getCanonicalFile()' 'Canonical storage containment check missing.'
require_literal "$ITEM_STORE" '!file.isFile()' 'Non-regular storage rejection missing.'
require_literal "$ITEM_STORE" '.onMalformedInput(CodingErrorAction.REPORT)' 'Malformed UTF-8 rejection missing.'
require_literal "$ITEM_STORE" '.onUnmappableCharacter(CodingErrorAction.REPORT)' 'Unmappable UTF-8 rejection missing.'
require_literal "$ITEM_STORE" 'BoundedInputStream boundedStream = new BoundedInputStream(' 'Bounded item-file reader missing.'
require_literal "$ITEM_STORE" "if (character == '\\n')" 'Strict LF item boundary parser missing.'
require_literal "$ITEM_STORE" 'item.length() > ItemPolicy.MAX_ITEM_BYTES' 'Streaming item-size guard missing.'
require_literal "$ITEM_STORE" 'stream.getFD().sync();' 'Temporary item data must be synced before replacement.'
require_literal "$ITEM_STORE" 'readFile(backup)' 'Backup must be validated before recovery.'
require_literal "$ITEM_STORE" 'setReadable(false, false)' 'Owner-only storage permission hardening missing.'
require_literal "$ITEM_STORE" 'new ItemFileTransaction().replace(' 'Atomic replacement transaction missing.'
require_literal "$ITEM_STORE" 'interface FilePermissions' 'Injectable permission boundary missing.'
require_literal "$HOST_STORAGE_TEST" 'test.doesNotReportFailureAfterInstallingHardenedTemporaryFile();' 'Post-install permission regression must execute.'

write_body=$(sed -n '/    void write(List<String> items)/,/    private File child/p' "$ITEM_STORE")
if printf '%s\n' "$write_body" | grep -Fq 'hardenPermissions(target)'; then
  fail 'ItemStore.write must not report failure after installing the hardened temporary file.'
fi

require_literal "$LIST_TRANSACTION" 'synchronized (items)' 'List mutation ownership must remain serialized.'
require_literal "$LIST_TRANSACTION" 'new ArrayList<String>(items)' 'Persistence must operate on a proposed snapshot.'
require_literal "$MAIN_ACTIVITY" 'writeItems(List<String> proposedItems)' 'Activity must persist proposed snapshots.'
require_literal "$MAIN_ACTIVITY" 'ItemPolicy.normalizeInput' 'UI input must use the shared item policy.'

if grep -Eq 'Log\.[a-zA-Z]+\([^;]*,[[:space:]]*(e|error|exception)\)' "$MAIN_ACTIVITY"; then
  fail 'Storage logs must not include exception-derived details.'
fi
if grep -Eq 'Log\.[a-zA-Z]+\([^;]*\+' "$MAIN_ACTIVITY"; then
  fail 'Storage logs must not include fridge item contents.'
fi

require_literal "$WORKFLOW" 'runs-on: ubuntu-24.04' 'Hosted runner must remain pinned.'
require_literal "$WORKFLOW" 'permissions:' 'Workflow permissions boundary missing.'
require_literal "$WORKFLOW" 'contents: read' 'Workflow contents permission must remain read-only.'
require_literal "$WORKFLOW" 'persist-credentials: false' 'Checkout credentials must not persist.'
require_literal "$WORKFLOW" 'java-version: "8"' 'Legacy Android gate must remain on Java 8.'
require_literal "$WORKFLOW" 'run: /usr/bin/make check' 'Hosted verification must use system Make.'
if grep -Eq 'uses: [^@]+@(main|master|v[0-9]+)$' "$WORKFLOW"; then
  fail 'Workflow actions must be pinned to immutable commits.'
fi

require_literal "$WRAPPER_PROPERTIES" 'distributionUrl=https\://services.gradle.org/distributions/gradle-2.2.1-all.zip' 'Gradle runtime URL changed.'
require_literal "$WRAPPER_PROPERTIES" 'distributionSha256Sum=1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab' 'Gradle runtime checksum changed.'
[ "$(hash_file "$WRAPPER_JAR")" = '7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172' ] || fail 'Gradle wrapper JAR provenance mismatch.'

[ -f "$ROOT_DIR/app/src/androidTest/java/garethpaul/com/fridge/ItemStoreInstrumentationTest.java" ] || fail 'Storage instrumentation coverage missing.'
[ -x "$ROOT_DIR/scripts/test-item-store.sh" ] || fail 'Host storage test gate missing or not executable.'
require_literal "$ROOT_DIR/scripts/test-item-store.sh" 'javac -source 1.7 -target 1.7 -encoding UTF-8 -d "$BUILD_DIR"' 'Host storage test must compile Unicode fixtures as UTF-8.'
[ -x "$ROOT_DIR/scripts/test-check-baseline.sh" ] || fail 'Mutation gate missing or not executable.'
[ -x "$ROOT_DIR/scripts/check-historical-baseline.sh" ] || fail 'Historical baseline gate missing or not executable.'
[ -x "$ROOT_DIR/scripts/test-makefile-root.sh" ] || fail 'Make authority harness missing or not executable.'
require_literal "$ROOT_DIR/Makefile" 'MAKEFLAGS must not be overridden' 'Make mode authority guard missing.'
require_literal "$ROOT_DIR/Makefile" 'MAKEFILES must be empty' 'Make startup-file guard missing.'
require_literal "$ROOT_DIR/Makefile" 'scripts/test-makefile-root.sh' 'Make authority harness is not in the default gate.'
require_literal "$ROOT_DIR/docs/plans/2026-06-21-android-fridge-system-make-boundary.md" 'Status: Completed' 'Make authority plan must be completed.'
require_literal "$ROOT_DIR/docs/plans/2026-06-26-precommit-permission-hardening.md" 'Status: Completed' 'Pre-commit permission hardening plan must be completed.'
require_literal "$ROOT_DIR/docs/plans/2026-06-26-combining-mark-only-items.md" 'Status: Completed' 'Combining-mark-only item plan must be completed.'
require_literal "$ROOT_DIR/scripts/test-makefile-root.sh" 'later fake-shell bypass boundary reproduction' 'Make authority harness must reproduce later fake-shell boundary.'
require_literal "$ROOT_DIR/scripts/test-makefile-root.sh" 'later double-colon append boundary reproduction' 'Make authority harness must reproduce double-colon append boundary.'
require_literal "$ROOT_DIR/scripts/test-makefile-root.sh" 'startup parse-time boundary reproduction' 'Make authority harness must reproduce startup parse-time boundary.'
require_literal "$ROOT_DIR/README.md" 'Caller-supplied later makefiles, including target-specific SHELL/.SHELLFLAGS overrides and double-colon public recipes, are outside the local Make trust boundary.' 'README must document caller-supplied Make boundary.'
require_literal "$ROOT_DIR/CHANGES.md" 'Documented caller-supplied later makefiles and startup parse-time Make code as outside the local Make trust boundary.' 'CHANGES must record the truthful Make boundary.'
require_literal "$ROOT_DIR/docs/plans/2026-06-21-android-fridge-system-make-boundary.md" 'Startup makefiles can run parse-time Make functions before the repository Makefile rejects them.' 'Make authority plan must document startup parse-time boundary.'

require_literal "$ROOT_DIR/SECURITY.md" 'malformed UTF-8' 'Security documentation must cover strict decoding.'
require_literal "$ROOT_DIR/SECURITY.md" 'line boundaries' 'Security documentation must cover strict line boundaries.'
require_literal "$ROOT_DIR/SECURITY.md" 'Unicode invisible-only items' 'Security documentation must cover invisible-only item rejection.'
require_literal "$ROOT_DIR/README.md" 'Unicode invisible-only entries are rejected' 'README must document Unicode-visible item validation.'
require_literal "$ROOT_DIR/VISION.md" 'Unicode-visible item content' 'Vision must preserve Unicode-visible item validation.'
require_literal "$ROOT_DIR/CHANGES.md" 'Rejected Unicode invisible-only fridge items' 'CHANGES must record Unicode-visible item validation.'
require_literal "$ROOT_DIR/CHANGES.md" 'Rejected combining-mark-only fridge items' 'CHANGES must record combining-mark-only validation.'
require_literal "$ROOT_DIR/docs/plans/2026-06-25-fridge-unicode-visible-items.md" 'Status: Completed' 'Unicode-visible item plan must be completed.'
require_literal "$ROOT_DIR/DEVICE_VERIFICATION.md" 'process death' 'Device verification must cover process death.'

"$ROOT_DIR/scripts/check-historical-baseline.sh"
