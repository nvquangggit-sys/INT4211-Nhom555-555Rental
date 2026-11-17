import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Khóa ký bản release nằm ngoài git (android/key.properties + *.jks).
val khoaProperties = Properties()
val tepKhoa = rootProject.file("key.properties")
if (tepKhoa.exists()) {
    khoaProperties.load(FileInputStream(tepKhoa))
}

android {
    namespace = "vn.nhom555.rental_client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Mã ứng dụng chứa 555 theo yêu cầu đề bài.
        applicationId = "vn.nhom555.rental_client"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (tepKhoa.exists()) {
                keyAlias = khoaProperties["keyAlias"] as String
                keyPassword = khoaProperties["keyPassword"] as String
                storeFile = file(khoaProperties["storeFile"] as String)
                storePassword = khoaProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Có key.properties thì ký bằng khóa release, không thì dùng debug key
            // để `flutter build apk` vẫn chạy được trên máy khác.
            signingConfig = if (tepKhoa.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
