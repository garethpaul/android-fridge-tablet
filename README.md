# Android Fridge Tablet

Legacy Android tablet app for maintaining a simple fridge list on-device.

## Toolchain

This project currently uses the original Android build stack:

- Gradle wrapper 2.2.1
- Android Gradle Plugin 1.1.0
- compile SDK 22 / target SDK 21
- Android build-tools 24.0.3
- Commons IO 2.0.1

Configure an Android SDK path before running Gradle:

```sh
export ANDROID_HOME=/home/gjones/android-sdk
export ANDROID_SDK_ROOT=/home/gjones/android-sdk
```

or create an untracked `local.properties` file:

```properties
sdk.dir=/path/to/android-sdk
```

## Verify

Run the SDK-free baseline check first:

```sh
scripts/check-baseline.sh
```

Then run Gradle with a compatible Android SDK:

```sh
ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew tasks --no-daemon
ANDROID_HOME=/home/gjones/android-sdk ANDROID_SDK_ROOT=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon
```

If Gradle reports that the SDK location cannot be found, configure
`ANDROID_HOME`, `ANDROID_SDK_ROOT`, or `local.properties` and rerun the command.

## Modernization Notes

This baseline keeps the app on Gradle 2.2.1, Android Gradle Plugin 1.1.0, and
target SDK 21 while moving build resolution to HTTPS Maven Central and compiling
against installed SDK packages with a host-compatible `aapt`. A future
modernization pass should update the Gradle stack, target SDK, storage behavior,
date handling, and behavior tests together with emulator or device verification.
