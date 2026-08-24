pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk chua duoc dat trong local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Ghim AGP 8.x: AGP 9 chi doc DSL moi, Flutter Gradle plugin chua tuong thich.
    // Flutter co canh bao "sap ngung ho tro" nhung day chi la warning, build van chay.
    id("com.android.application") version "8.12.0" apply false
    // Flutter 3.47 yeu cau Kotlin toi thieu 2.2.20
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
