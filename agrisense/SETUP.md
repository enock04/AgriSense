# AgriSense — Developer Setup Guide

## Required Secret Files (not in git)

These files are excluded from version control. You must add them manually after cloning..

---

### 1. `.env` — Weather API Key

Create `agrisense/.env`:
```
WEATHER_API_KEY=your_openweathermap_api_key_here
```

Get your key at: https://openweathermap.org/api

---

### 2. `android/app/google-services.json` — Firebase Config

1. Go to [Firebase Console](https://console.firebase.google.com) → AgriSense project
2. Project Settings → Your apps → Android app (`com.agrisense.app`)
3. Click **"google-services.json"** → Download
4. Place at: `android/app/google-services.json`

---

### 3. `android/app/agrisense-release.keystore` — Release Signing

For release builds only. Contact the project owner for the keystore file.

Also create `android/key.properties`:
```
storePassword=<password>
keyPassword=<password>
keyAlias=agrisense
storeFile=agrisense-release.keystore
```

---

## Running the App

```bash
flutter pub get
flutter run
```

## Test Credentials (debug only)

| Field | Value |
|---|---|
| Phone | `+250793442608` |
| OTP   | `000000` |

> Test bypass is disabled in release builds (`kDebugMode` guard).
