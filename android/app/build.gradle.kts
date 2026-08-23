plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Plugin cua Flutter phai dung sau 2 plugin tren
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lovesync.app"

    // Cac thu vien AndroidX moi doi compile toi thieu 36
    compileSdk = 36

    compileOptions {
        // Can cho mot so plugin dung API Java 8+ tren may Android cu
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.lovesync.app"
        minSdk = 23      // image_picker yeu cau toi thieu 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // Ky bang debug key de cai truc tiep, khong dua len Play Store
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
