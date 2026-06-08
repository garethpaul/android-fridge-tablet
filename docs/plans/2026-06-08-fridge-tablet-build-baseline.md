---
title: Fridge Tablet Build Baseline
type: chore
status: completed
date: 2026-06-08
---

# Fridge Tablet Build Baseline

## Summary

Make the legacy Fridge tablet Android app reproducible in the local SDK environment by removing duplicate Gradle plugin application, moving dependency resolution to HTTPS Maven Central, compiling against an installed Android platform while preserving runtime target behavior, and documenting the verification path.

---

## Problem Frame

The repository has a small Android app with Gradle 2.2.1 and Android Gradle Plugin 1.1.0, but it has no README, relies on JCenter repository declarations, applies two Android plugins in the app module, and currently cannot configure here because SDK platform 21 is not installed. The local SDK does include Android platform 22 and build-tools 24.0.3, which are suitable for a conservative build baseline while leaving `targetSdkVersion 21` unchanged.

---

## Requirements

- R1. The app module must apply only the `com.android.application` plugin.
- R2. Build repositories must use explicit HTTPS Maven Central URLs instead of JCenter.
- R3. The app must compile against an Android platform and build-tools package available in the local SDK.
- R4. `targetSdkVersion` must remain 21 to avoid runtime behavior changes in this baseline pass.
- R5. The repository must include a README describing the legacy toolchain, local SDK requirements, and verification commands.
- R6. A local source check must run without Android SDK setup and verify the build baseline declarations.
- R7. Larger migrations to a modern Android Gradle Plugin, AndroidX, current SDK targets, and app behavior tests must remain explicit follow-up work.

---

## Key Technical Decisions

- **Preserve runtime targeting:** Change `compileSdkVersion` and `buildToolsVersion` only; leave `minSdkVersion` and `targetSdkVersion` intact.
- **Use installed SDK packages:** Use compile SDK 22 and build-tools 24.0.3 because they exist under `/home/gjones/android-sdk` and `aapt` runs on this host.
- **Remove duplicate plugin application:** Keep `apply plugin: 'com.android.application'` and delete the obsolete second `apply plugin: 'android'`.
- **Replace JCenter with explicit HTTPS Maven Central:** Android Gradle Plugin 1.1.0 and Commons IO 2.0.1 are available from Maven Central, so JCenter is unnecessary for this baseline.
- **Add SDK-free checks:** A shell script can guard the chosen baseline before running Gradle.

---

## Scope Boundaries

- This pass does not update Gradle wrapper 2.2.1 or Android Gradle Plugin 1.1.0.
- This pass does not change `targetSdkVersion`, app storage behavior, UI, or list persistence behavior.
- This pass does not add emulator or instrumentation tests.
- This pass does not replace Commons IO or refactor file persistence.

---

## Implementation Units

### U1. Stabilize Gradle Build Metadata

- **Goal:** Make Gradle configuration deterministic and runnable with the local SDK.
- **Files:** `build.gradle`, `app/build.gradle`
- **Patterns:** Preserve the existing legacy Gradle structure; change only repositories, duplicate plugin application, compile SDK, and build-tools values.
- **Test Scenarios:**
  - `app/build.gradle` applies `com.android.application` once and no longer applies `android`.
  - `build.gradle` uses `https://repo1.maven.org/maven2` in buildscript and allprojects repositories.
  - `app/build.gradle` uses compile SDK 22 and build-tools 24.0.3.
  - `app/build.gradle` keeps `targetSdkVersion 21`.
- **Verification:** `scripts/check-baseline.sh`, `ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew tasks --no-daemon`

### U2. Add SDK-Free Baseline Check

- **Goal:** Provide a fast quality gate for the build baseline.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell with repo-root detection and clear failure messages.
- **Test Scenarios:**
  - The script fails if JCenter is reintroduced.
  - The script fails if the duplicate `apply plugin: 'android'` returns.
  - The script fails if compile SDK, build-tools, or target SDK declarations drift from this baseline.
  - The script succeeds without Android SDK configuration.
- **Verification:** `scripts/check-baseline.sh`

### U3. Developer Documentation

- **Goal:** Make the repository understandable for future maintenance.
- **Files:** `README.md`
- **Patterns:** Short sections covering purpose, toolchain, setup, verification, and deferred modernization.
- **Test Scenarios:**
  - README lists Gradle 2.2.1, Android Gradle Plugin 1.1.0, compile SDK 22, target SDK 21, and build-tools 24.0.3.
  - README lists `scripts/check-baseline.sh`.
  - README lists Gradle task and debug assembly commands with Android SDK environment variables.
  - README explains that broader SDK/plugin modernization is deferred.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Android Gradle Plugin 1.1.0 and Gradle 2.2.1 are obsolete and may require Java 8 for reliable local builds.
- Compile SDK 22 is only a build-time platform bump; a later target SDK modernization should be tested on a device or emulator.
- The app still has no behavior tests for item persistence, empty item handling, or date formatting.

---

## Sources / Research

- `build.gradle` contains JCenter repository declarations and Android Gradle Plugin 1.1.0.
- `app/build.gradle` contains duplicate Android plugin application, compile SDK 21, build-tools 21.1.2, target SDK 21, and Commons IO 2.0.1.
- `gradle/wrapper/gradle-wrapper.properties` pins Gradle 2.2.1 over HTTPS.
- `app/src/main/java/garethpaul/com/fridge/MainActivity.java` contains the current list persistence and date display behavior.
- `/home/gjones/android-sdk` currently lacks platform 21 but includes platform 22 and build-tools 24.0.3.
