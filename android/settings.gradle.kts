pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
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
    // 相容窗口說明：alarm 引擎的構建腳本尚未適配 AGP 9 移除的舊 DSL，
    // 且其 kotlinx-serialization 編譯器插件鎖定 Kotlin 2.1.0（K2 插件嚴格對版）。
    // 故取 AGP 8.11.1 + Kotlin 2.1.0，並以 suppressUnsupportedCompileSdk
    // 對 API 37 編譯（見 gradle.properties）。
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
