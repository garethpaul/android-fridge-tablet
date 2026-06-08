---
title: Fridge Lint Resource Baseline
type: chore
status: completed
date: 2026-06-08
---

# Fridge Lint Resource Baseline

## Summary

Clean the remaining Android lint findings in the legacy Fridge tablet UI while
preserving the existing Gradle and target SDK baseline.

## Requirements

- R1. Keep the build baseline on Gradle 2.2.1, Android Gradle Plugin 1.1.0,
  compile SDK 22, build-tools 24.0.3, and target SDK 21.
- R2. Move visible UI text into string resources.
- R3. Give the item input an explicit hint and text input type.
- R4. Remove unused starter resources and redundant RTL attributes.
- R5. Document only the narrow lint suppressions needed by the old Android
  toolchain and preserved target SDK.

## Verification

- `scripts/check-baseline.sh`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew lint --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew test --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`
