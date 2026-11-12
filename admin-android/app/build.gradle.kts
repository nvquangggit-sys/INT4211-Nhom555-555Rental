import java.util.Properties

plugins {
    id("com.android.application")
}

// Thông tin ký APK release. Với đồ án, khóa demo được đặt sẵn trong repo
// để giảng viên có thể build lại; khi triển khai thật hãy đổi khóa và
// chuyển mật khẩu sang biến môi trường.
val khoaProps = Properties().apply {
    val tep = rootProject.file("keystore.properties")
    if (tep.exists()) {
        tep.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.nhom555.rentaladmin"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.nhom555.rentaladmin"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            storeFile = rootProject.file(
                khoaProps.getProperty("storeFile") ?: "keystore/555rental-release.jks")
            storePassword = khoaProps.getProperty("storePassword") ?: "555rental"
            keyAlias = khoaProps.getProperty("keyAlias") ?: "nhom555"
            keyPassword = khoaProps.getProperty("keyPassword") ?: "555rental"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.recyclerview:recyclerview:1.4.0")
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel:2.8.7")
    implementation("androidx.lifecycle:lifecycle-livedata:2.8.7")

    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")
    implementation("com.github.bumptech.glide:glide:4.16.0")

    testImplementation("junit:junit:4.13.2")
}
