plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // لو القديمة شغالة عندك (kotlin-android) ماشي، بس دي الأحدث
    // لازم ييجي بعد Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.to_do"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.to_do"
        // flutter_local_notifications محتاج minSdk 21 على الأقل
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // مهم عشان خطأ desugaring اللي كان ظاهر قبل كده
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // مؤقتاً استخدم توقيع debug عشان تقدر تبني Release محلياً
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // مكتبات الـ desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
