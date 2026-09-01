# Flutter Android SDK & Device Deployment Troubleshooting Guide

This document records the exact issues encountered, root causes, and automated step-by-step resolution commands applied to fix Flutter Android toolchain issues and run Flutter apps on connected Android hardware in Linux.

---

## 🔍 Initial Problems Encountered

When running `flutter doctor` or attempting `flutter run`, the following errors occurred:

1. **`cmdline-tools component is missing`**:
   `Android toolchain - develop for Android devices (Android SDK version 36.1.0) ✗ cmdline-tools component is missing.`
2. **`Android sdkmanager not found / License status unknown`**:
   `Android sdkmanager not found. Update to the latest Android SDK and ensure that the cmdline-tools are installed.`
3. **`Devices found, but are not supported by this project`**:
   Flutter detected the connected Android phone (`CPH2691`), but could not build because the `android/` and `linux/` platform wrappers had not been generated for the project.

---

## 🛠️ Step-by-Step Technical Resolution

### 1. Downloaded & Installed Android Command-Line Tools (`cmdline-tools`)
Rather than opening Android Studio UI, official Android Command Line Tools package was downloaded and unzipped into the proper folder structure required by Flutter:

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools"
curl -sSL -o "$HOME/Android/Sdk/cmdline-tools/cmdline-tools.zip" \
  "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

cd "$HOME/Android/Sdk/cmdline-tools"
unzip -q cmdline-tools.zip
rm -rf latest
mv cmdline-tools latest
```

> **Required Folder Structure**: `$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager`

---

### 2. Configured Flutter Android SDK Path
Explicitly pointed Flutter to the local Android SDK directory:

```bash
export PATH="$HOME/Android/Sdk/cmdline-tools/latest/bin:$PATH"
flutter config --android-sdk "$HOME/Android/Sdk"
```

---

### 3. Automatically Accepted All Android SDK Licenses
Ran non-interactive license acceptance to approve all SDK agreements:

```bash
yes | flutter doctor --android-licenses
```

Output confirmed: `All SDK package licenses accepted`.

---

### 4. Generated Native Platform Wrappers (`android/` & `linux/`)
Created native platform scaffolding for the project without affecting existing `lib/` Dart source code:

```bash
cd "/run/media/nepal/Backup/VS Code projects/expense_debt_manager"
flutter create --platforms=android,linux .
```

---

### 5. Verified Connection & Deployed to Connected Phone (`CPH2691`)
1. Verified connected devices:
   ```bash
   flutter devices
   # Output: CPH2691 (mobile) • e9c3eb44 • android-arm64 • Android 16 (API 36)
   ```
2. Built & launched debug APK directly onto the phone:
   ```bash
   flutter run -d e9c3eb44
   ```

---

## ✅ Verification Checklist

Run these commands anytime in the future to verify your system readiness:

```bash
# 1. Verify Flutter environment health
flutter doctor

# 2. Check connected Android devices
adb devices
flutter devices

# 3. Clean and rebuild project
flutter clean
flutter pub get
flutter run
```
