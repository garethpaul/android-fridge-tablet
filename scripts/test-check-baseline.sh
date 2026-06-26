#!/bin/sh
set -eu

SCRIPT_DIR=$(dirname -- "$0")
case $SCRIPT_DIR in
  /*) ROOT_DIR=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd) ;;
  *) ROOT_DIR=$(CDPATH='' cd "./$SCRIPT_DIR/.." && pwd) ;;
esac
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-fridge-mutations.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

copy_repo() {
  destination=$1
  mkdir -p "$destination"
  tar -C "$ROOT_DIR" --exclude=.git --exclude=build --exclude=.gradle -cf - . | tar -C "$destination" -xf -
}

expect_rejected() {
  name=$1
  mutation=$2
  candidate="$TEMP_ROOT/$name"
  copy_repo "$candidate"
  (cd "$candidate" && sh -c "$mutation")
  if "$candidate/scripts/check-baseline.sh" >/dev/null 2>&1; then
    printf 'Mutation was not rejected: %s\n' "$name" >&2
    exit 1
  fi
}

expect_rejected no-fsync \
  "perl -0pi -e 's/            stream\\.getFD\\(\\)\\.sync\\(\\);\\n//' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected post-install-permission-mutation \
  "perl -0pi -e 's/(            throw new IOException\(\"Unable to replace fridge item file\"\);\n        }\n)(    }\n\n    private File child)/\$1        hardenPermissions(target);\n\$2/' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected no-permission-commit-regression \
  "perl -0pi -e 's/        test\\.doesNotReportFailureAfterInstallingHardenedTemporaryFile\\(\\);\\n//' scripts/host-tests/garethpaul/com/fridge/ItemStoreHostTest.java"
expect_rejected lenient-decoder \
  "perl -0pi -e 's/\\.onMalformedInput\\(CodingErrorAction\\.REPORT\\)/.onMalformedInput(CodingErrorAction.REPLACE)/' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected no-canonical-check \
  "sed -i.bak '/!file.getAbsoluteFile().equals(file.getCanonicalFile())/d' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected unbounded-reader \
  "perl -0pi -e 's/BoundedInputStream boundedStream = new BoundedInputStream/InputStream boundedStream = new BoundedInputStream/' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected permissive-line-boundary \
  "perl -0pi -e 's/if \\(character == '\''\\\\n'\''\\)/if (character == '\''\\\\n'\'' || character == '\''\\\\r'\'')/' app/src/main/java/garethpaul/com/fridge/ItemStore.java"
expect_rejected unbounded-items \
  "perl -0pi -e 's/MAX_ITEMS = 512/MAX_ITEMS = 500000/' app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
expect_rejected unicode-separators-visible \
  "perl -0pi -e 's/Character\.isSpaceChar\(codePoint\)/false/g' app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
expect_rejected unicode-format-visible \
  "perl -0pi -e 's/[[:space:]]*\\|\\| Character\.getType\(codePoint\) == Character\.FORMAT//' app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
expect_rejected unicode-variation-selectors-visible \
  "perl -0pi -e 's/[[:space:]]*\\|\\| \\(codePoint >= 0xFE00 && codePoint <= 0xFE0F\\)//' app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
expect_rejected unicode-combining-marks-visible \
  "perl -0pi -e 's/ && !isCombiningMark\\(codePoint\\)//' app/src/main/java/garethpaul/com/fridge/ItemPolicy.java"
expect_rejected no-combining-mark-regression \
  "perl -0pi -e 's/        test\\.rejectsCombiningMarkOnlyItems\\(\\);\\n//' scripts/host-tests/garethpaul/com/fridge/ItemStoreHostTest.java"
expect_rejected exported-launcher-disabled \
  "perl -0pi -e 's/android:exported=\"true\"/android:exported=\"false\"/' app/src/main/AndroidManifest.xml"
expect_rejected persistent-checkout-credentials \
  "perl -0pi -e 's/persist-credentials: false/persist-credentials: true/' .github/workflows/check.yml"
expect_rejected exception-bearing-log \
  "perl -0pi -e 's/Log\\.w\\(LOG_TAG, \"Unable to write fridge items\"\\);/Log.w(LOG_TAG, \"Unable to write fridge items\", e);/' app/src/main/java/garethpaul/com/fridge/MainActivity.java"
