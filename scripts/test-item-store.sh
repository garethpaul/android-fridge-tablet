#!/bin/sh
set -eu

SCRIPT_DIR=$(dirname -- "$0")
case $SCRIPT_DIR in
  /*) ROOT_DIR=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd) ;;
  *) ROOT_DIR=$(CDPATH='' cd "./$SCRIPT_DIR/.." && pwd) ;;
esac
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-fridge-host-tests.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

javac -source 1.7 -target 1.7 -encoding UTF-8 -d "$BUILD_DIR" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemPolicy.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemStore.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemFileTransaction.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java" \
  "$ROOT_DIR/scripts/host-tests/garethpaul/com/fridge/FileInputStreamCompat.java" \
  "$ROOT_DIR/scripts/host-tests/garethpaul/com/fridge/ItemStoreHostTest.java"

java -cp "$BUILD_DIR" garethpaul.com.fridge.ItemStoreHostTest
