plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_premier"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    
    // Explicitly set build tools version to avoid 25.0.1 error
    // This will use the latest compatible version automatically
    // buildToolsVersion is handled by Android Gradle Plugin 8.x+

    compileOptions {
        // Enable core library desugaring for Java 8+ APIs used by some plugins
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.my_premier"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required when core library desugaring is enabled
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Google Services plugin - temporarily disabled to fix build tools version conflict
// Uncomment after fixing the 25.0.1 error
// apply(plugin = "com.google.gms.google-services")