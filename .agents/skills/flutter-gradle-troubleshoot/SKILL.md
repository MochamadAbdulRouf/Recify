---
name: flutter-gradle-troubleshoot
description: >-
  Diagnose and fix Flutter Android build failures caused by incompatible Gradle,
  Android Gradle Plugin (AGP), or Kotlin versions. Use this skill when the user
  encounters errors like "Gradle version is lower than Flutter's minimum supported
  version", "Android Gradle Plugin version is lower than Flutter's minimum",
  "Kotlin version is lower than Flutter's minimum", or "Starting AGP 9+, only the
  new DSL interface will be read" during flutter run or flutter build.
---

# Flutter Gradle / AGP / Kotlin Version Troubleshoot

This skill resolves Flutter Android build failures caused by version mismatches
between Gradle, Android Gradle Plugin (AGP), and Kotlin.

---

## Symptoms

The build fails with one or more of these errors:

- `Your project's Gradle version (X) is lower than Flutter's minimum supported version of Y`
- `Your project's Android Gradle Plugin version (X) is lower than Flutter's minimum supported version of Y`
- `Your project's Kotlin version (X) is lower than Flutter's minimum supported version of Y`
- `Starting AGP 9+, only the new DSL interface will be read`
- `Gradle task assembleDebug failed with exit code 1`

---

## Diagnosis Steps

### 1. Identify the current Flutter version and its requirements

```bash
flutter --version
```

Flutter enforces **minimum versions** for Gradle, AGP, and Kotlin. These change
with each Flutter release. The error messages will tell you the exact minimums.

### 2. Check the three key configuration files

| Setting | File | What to look for |
|---------|------|-------------------|
| **Gradle version** | `android/gradle/wrapper/gradle-wrapper.properties` | `distributionUrl` line — the version number in the zip filename |
| **AGP version** | `android/settings.gradle` | `id "com.android.application" version "X.Y.Z"` in the `plugins` block |
| **Kotlin version** | `android/settings.gradle` | `id "org.jetbrains.kotlin.android" version "X.Y.Z"` in the `plugins` block |
| **DSL flags** | `android/gradle.properties` | `android.newDsl` and `android.builtInKotlin` flags |

### 3. Check for deprecated properties

In `android/gradle.properties`, look for:
- `kotlin.incremental=false` — **deprecated in Gradle 8.14+**, remove it
- `kotlin.incremental.useClasspathSnapshot=false` — **deprecated**, remove it

---

## Fix Procedure

### Step 1: Upgrade Gradle version

Edit `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
# Change the version in distributionUrl to meet Flutter's minimum
# Example: upgrading from 8.9 to 8.14.1
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.1-all.zip
```

> [!IMPORTANT]
> Always verify the Gradle distribution URL exists before setting it.
> Gradle 9.x may not yet be available at `services.gradle.org/distributions/`.
> Use the highest **available** version that meets Flutter's minimum.

### Step 2: Upgrade AGP version

Edit the `plugins` block in `android/settings.gradle`:

```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.11.1" apply false  // Update this
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false  // Update this
}
```

> [!WARNING]
> AGP and Gradle versions must be compatible:
> - AGP 8.x works with Gradle 8.x
> - AGP 9.x requires Gradle 9.1.0+
> If Gradle 9.x is not yet available, stay on the latest AGP 8.x that meets Flutter's minimum.

### Step 3: Upgrade Kotlin version

Update the Kotlin version in the same `plugins` block in `android/settings.gradle`
(shown in Step 2 above).

### Step 4: Handle `android.newDsl` flag in `gradle.properties`

| Scenario | Action |
|----------|--------|
| Using **AGP 8.x** | Keep `android.newDsl=false` to opt out of AGP 9 new DSL |
| Using **AGP 9.x** | Remove `android.newDsl=false` — new DSL is mandatory |

### Step 5: Remove deprecated Kotlin incremental properties

Remove these lines from `android/gradle.properties` if present:

```properties
# REMOVE these deprecated lines:
# kotlin.incremental=false
# kotlin.incremental.useClasspathSnapshot=false
```

### Step 6: Clean and rebuild

```bash
cd android
./gradlew clean    # or .\gradlew.bat clean on Windows
cd ..
flutter run -d <device-id>
```

> [!NOTE]
> The first build after upgrading Gradle will download the new distribution,
> which can take several minutes depending on internet speed.

---

## Version Compatibility Matrix (as of Flutter 3.47.2, August 2026)

| Dependency | Minimum Required | Recommended | Config Location |
|------------|-----------------|-------------|-----------------|
| **Gradle** | 8.14.0 | 8.14.1 | `gradle-wrapper.properties` |
| **AGP** | 8.11.1 | 8.11.1 | `settings.gradle` plugins block |
| **Kotlin** | 2.2.20 | 2.2.20 | `settings.gradle` plugins block |
| **Java** | JDK 17 | JDK 17 | `build.gradle` compileOptions |

> [!TIP]
> Flutter's minimum versions change with each release. Always read the exact
> version numbers from the error messages rather than relying on this table,
> as it may be outdated for newer Flutter versions.

---

## Common Pitfalls

1. **Upgrading one dependency without the others**: Gradle, AGP, and Kotlin versions
   are interdependent. Always check all three when upgrading.

2. **Gradle distribution not available**: Not all Gradle versions exist on the
   distribution server. Verify the URL before committing to a version.
   The format is: `https://services.gradle.org/distributions/gradle-{VERSION}-all.zip`

3. **Warnings vs Errors**: Messages saying "support will soon be dropped" are
   **warnings**, not errors. They won't fail the build but indicate you should
   plan to upgrade in the future.

4. **AGP 9+ new DSL**: If you see "Starting AGP 9+, only the new DSL interface
   will be read", either:
   - Set `android.newDsl=false` in `gradle.properties` (if staying on AGP 8.x)
   - Or upgrade to AGP 9.x and remove the flag (requires Gradle 9.1.0+)

5. **Cached Gradle daemons**: After upgrading, old daemons may be incompatible.
   Gradle will start new ones automatically but this adds time to the first build.

6. **Legacy project structure**: Older Flutter templates may define AGP in
   `android/build.gradle` via `classpath 'com.android.tools.build:gradle:X.Y.Z'`
   instead of the `settings.gradle` plugins block. Check both files.
