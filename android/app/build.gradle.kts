plugins {
    id("com.android.application")
    id("kotlin-android")

    // ✅ FlutterFire Configuration Plugin
    id("com.google.gms.google-services")

    // ✅ Flutter plugin (must come last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rewire_app"
    compileSdk = 36 // ✅ Explicitly specify compileSdk for stability
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.rewire_app"
        minSdk = flutter.minSdkVersion // ✅ Required for Firebase + file_picker + multiDex
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Enable multiDex for large Firebase projects
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Option 1: Disable resource shrinking completely (recommended for now)
            isMinifyEnabled = false
            isShrinkResources = false
        }

        debug {
            // ✅ Ensure debug build doesn’t try to shrink anything
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }


    // ✅ Ensure compatibility with Flutter asset & plugin system
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase Core for FlutterFire initialization
    implementation("com.google.firebase:firebase-analytics")

    // ✅ MultiDex support (needed for large Flutter + Firebase apps)
    implementation("androidx.multidex:multidex:2.0.1")
}
