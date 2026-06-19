#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-fridge-host-tests.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

javac -source 1.7 -target 1.7 -d "$BUILD_DIR" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemPolicy.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemStore.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemFileTransaction.java" \
  "$ROOT_DIR/app/src/main/java/garethpaul/com/fridge/ItemListTransaction.java" \
  "$ROOT_DIR/app/src/test/java/garethpaul/com/fridge/FileInputStreamCompat.java" \
  "$ROOT_DIR/app/src/test/java/garethpaul/com/fridge/ItemStoreHostTest.java"

java -cp "$BUILD_DIR" garethpaul.com.fridge.ItemStoreHostTest
