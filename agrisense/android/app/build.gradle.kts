import java.util.Properties

// Load signing config from key.properties
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}
plugins {
    id("com.android.application")
    // Flutter's built-in Kotlin support — do NOT add id("kotlin-android") here.
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.agrisense.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.agrisense.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // NOTE: Flutter's Gradle "Upgrading build.gradle.kts" auto-migration has silently
        // reverted this back to `flutter.minSdkVersion` (which resolves to 24, not 23) on
        // every one of several occasions during this project's development. There is no
        // supported override for flutter.minSdkVersion in the Flutter SDK itself — always
        // re-check this line after any `flutter run`/`flutter build` output that mentions
        // "Upgrading build.gradle.kts", especially right before a release build.
        minSdk = flutter.minSdkVersion  // Firebase Auth requires API 23+ — do not replace with flutter.minSdkVersion (see note above)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (keyPropertiesFile.exists()) {
                signingConfig = signingConfigs.create("release") {
                    storeFile = file(keyProperties["storeFile"] as String)
                    storePassword = keyProperties["storePassword"] as String
                    keyAlias = keyProperties["keyAlias"] as String
                    keyPassword = keyProperties["keyPassword"] as String
                }
            } else {
                // Fallback to debug signing when key.properties not present
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

