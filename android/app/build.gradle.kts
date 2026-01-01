plugins {
    id("com.android.application")
    id("kotlin-android")
    // Plugin Flutter
    id("dev.flutter.flutter-gradle-plugin")

    // Plugin Google Services pour Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.smart_fruit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.smart_fruit"
        minSdk = 26  // tflite_flutter nécessite minSdk 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Les dépendances Firebase sont gérées par les plugins Flutter
    // (firebase_core, firebase_auth, cloud_firestore dans pubspec.yaml)
    // Le plugin google-services est suffisant pour traiter google-services.json
}
