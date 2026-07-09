plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.monogatari.clock"
    // Android 17（API 37）：編譯與行為基準皆對齊最新平台。
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 精確排程用到 java.time，Android 8.0（API 26）上仍需脫糖庫。
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.monogatari.clock"
        // 支援跨度：Android 8.0（API 26）至 Android 17（API 37）。
        // targetSdk 37 的關鍵合規點（本應用已按此設計）：
        //  · 後台音訊收緊 —— 鬧鐘持有 USE_EXACT_ALARM 且聲音走
        //    USAGE_ALARM 音訊流，屬平台明文豁免路徑
        //  · 大屏不可鎖定方向 —— 本應用從未鎖向，佈局自適應
        minSdk = 26
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 發佈版不簽名：產物為 app-release-unsigned.apk，簽名交由發佈者完成。
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
