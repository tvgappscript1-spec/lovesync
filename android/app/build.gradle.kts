import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Plugin cua Flutter phai dung sau 2 plugin tren
    id("dev.flutter.flutter-gradle-plugin")
}

// Doc thong tin khoa ky tu android/key.properties
val keyProps = Properties()
val keyPropsFile = rootProject.file("key.properties")
if (keyPropsFile.exists()) {
    keyProps.load(FileInputStream(keyPropsFile))
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

    defaultConfig {
        applicationId = "com.lovesync.app"
        minSdk = 23      // image_picker yeu cau toi thieu 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            if (keyPropsFile.exists()) {
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Ky bang khoa CO DINH trong repo.
            // Nho cung mot chu ky, moi lan gui APK moi la cai de len ban cu
            // duoc ngay, KHONG mat du lieu. Neu doi khoa (vd dung debug key
            // do CI sinh moi moi lan) thi Android se tu choi cai de.
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Kotlin 2.2 danh dau kotlinOptions la cu -> dung compilerOptions.
// Khoi nay o cap cao nhat, KHONG nam trong android { }.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
