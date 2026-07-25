# 🌱 AgriSense

**Smart Farming Decision-Support Platform for Rwandan Smallholder Farmers**

AgriSense is a Flutter MVP that delivers localised agricultural education, real-time weather advisories, community knowledge sharing, and personalised crop guidance — in both English and Kinyarwanda — to farmers across Rwanda's 30 districts.

---

## Features

- **Two-factor authentication** — Phone OTP (Firebase) + Google Sign-In
- **Personalised onboarding** — language, farmer type, district, crop selection
- **Real-time weather** — OpenWeatherMap integration with district-level advisories and 5-day forecast
- **Learning library** — lesson content streamed from Firestore with offline progress tracking
- **Community forum** — post questions, upvote answers, district filtering
- **Admin panel** — seed/manage content, view community posts
- **Bilingual UI** — English + Kinyarwanda throughout

---

## Architecture

The project follows **Flutter Clean Architecture** with three distinct layers:

```
lib/
├── domain/            # Pure Dart — entities + repository interfaces
│   ├── entities/
│   └── repositories/
├── data/              # Data sources + DTOs + repository implementations
│   ├── datasources/
│   │   ├── local/     # SharedPreferences wrapper
│   │   └── remote/    # Firebase Auth, Firestore, Weather API
│   ├── models/        # Firestore DTOs (fromFirestore / toFirestore)
│   └── repositories/  # Concrete implementations
└── presentation/      # UI — providers, screens, theme
    ├── providers/      # ChangeNotifier providers (AppProvider + split providers)
    ├── screens/        # All screens organised by feature
    └── theme/          # AppColors, AppTheme
```

**State management:** Provider (ChangeNotifier). `AppProvider` is the single presentation-layer coordinator — screens have zero direct Firebase/Firestore dependencies.

**Dependency injection:** All repositories are injected into `AppProvider` via its constructor in `main.dart`. No service locators or global singletons.

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.41.9+ |
| Dart | 3.11.5+ |
| Android SDK | API 23+ |
| A Firebase project | — |

### 1. Clone the repository

```bash
git clone <repo-url>
cd agrisense
```

### 2. Configure Firebase

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Phone and Google sign-in providers
3. Enable **Cloud Firestore** in test mode (or apply `firestore.rules`)
4. Download `google-services.json` → place at `android/app/google-services.json`
5. Register your SHA-1 fingerprint in Firebase for Google Sign-In

> **Note:** `google-services.json` is git-ignored. Never commit it.

### 3. Add OpenWeatherMap API key

Create a `.env` file in the project root:

```
WEATHER_API_KEY=your_openweathermap_api_key_here
```

Get a free key at [openweathermap.org/api](https://openweathermap.org/api).

> **Note:** `.env` is git-ignored. Never commit it.

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Run the app

```bash
flutter run
```

---

## Running Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# With coverage
flutter test --coverage
```

The test suite includes:
- `test/unit/user_profile_test.dart` — UserProfile entity (copyWith, FarmerType, Crop)
- `test/unit/lesson_test.dart` — Lesson entity (withProgress, isCompleted, isStarted, clamping)
- `test/unit/community_post_test.dart` — CommunityPost entity (copyWith, bilingual fields)
- `test/widget_test.dart` — AppProvider smoke test with stub repositories (no live Firebase)

---

## Security

The following files are **git-ignored** and must never be committed:

| File | Contains |
|------|---------|
| `.env` | OpenWeatherMap API key |
| `android/app/google-services.json` | Firebase project config |
| `android/key.properties` | Signing keystore credentials |
| `*.keystore` / `*.jks` | Android signing keys |

The debug-only test phone bypass (`+250793442608` / `000000`) is guarded by `kDebugMode` and compiled out of release builds.

---

## Firestore Collections

See `AgriSense_ERD.svg` for the full entity-relationship diagram.

| Collection | Purpose |
|-----------|---------|
| `users/{uid}` | Farmer profile (name, phone, crops, district, language) |
| `users/{uid}/progress` | Per-lesson progress (0.0 – 1.0) |
| `lessons` | Learning content (streamed, ordered, filterable by crop/topic) |
| `community_posts` | Farmer questions with bilingual text + upvote count |
| `community_posts/{id}/upvotes` | Per-user upvote records (transactional) |
| `tips` | Daily tips (rotated by day-of-month) |
| `Config/admin` | Admin UIDs + phone numbers |

---

## Accessibility

The colour palette meets **WCAG 2.1 AA** (4.5:1 minimum contrast on white):

| Token | Hex | Contrast |
|-------|-----|---------|
| `gray900` | `#1A1F1A` | 16.8:1 ✅ |
| `gray700` | `#515D51` | 7.3:1 ✅ |
| `gray600` | `#637163` | 5.2:1 ✅ |
| `gray500` | `#677767` | 4.8:1 ✅ |
| `green700` | `#2A8139` | 4.6:1 ✅ |
| `amber600` | `#8A5D00` | 5.8:1 ✅ |
| `red600` | `#D22222` | 4.6:1 ✅ |

`gray400` (`#9EABA0`, 2.4:1) is reserved for placeholder / hint / disabled text only, which is WCAG-exempt.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI framework | Flutter 3.41.9 / Material 3 |
| State management | Provider (ChangeNotifier) |
| Auth | Firebase Auth (Phone OTP + Google Sign-In) |
| Database | Cloud Firestore |
| Local storage | SharedPreferences |
| Weather | OpenWeatherMap API |
| Localisation | Custom `AppStrings` (EN + RW) |

---

## Project Structure (key files)

```
lib/
├── main.dart                          # DI assembly + app root
├── domain/
│   ├── entities/                      # UserProfile, Lesson, CommunityPost, WeatherData …
│   └── repositories/                  # Abstract interfaces
├── data/
│   ├── datasources/local/             # PreferencesLocalDatasource
│   ├── datasources/remote/            # AuthRemoteDatasource, FirestoreRemoteDatasource
│   ├── models/                        # UserModel, LessonModel, CommunityPostModel
│   └── repositories/                  # AuthRepositoryImpl, UserRepositoryImpl …
└── presentation/
    ├── providers/app_provider.dart    # Single coordinator; all screens read from this
    └── screens/                       # home, weather, learn, community, profile, auth, …

test/
├── unit/                              # Pure-Dart entity tests
└── widget_test.dart                   # Smoke test with stub repositories

AgriSense_ERD.svg                      # Entity-relationship diagram
firestore.rules                        # Production security rules
```

---

*Built as a Flutter final-year project demonstrating Clean Architecture, Firebase integration, and bilingual UX for Rwandan smallholder farmers.*
