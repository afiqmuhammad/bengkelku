<<<<<<< HEAD
// Import diletakkan di bagian paling atas file.
import java.util.Properties
import java.io.FileInputStream

=======
import java.util.Properties
import java.io.FileInputStream


>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

<<<<<<< HEAD
// Logika untuk memuat file properties diletakkan setelah blok plugins.
=======
>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
<<<<<<< HEAD
    namespace = "com.bengkel.bengkelku" // Ganti dengan package kamu yang unik
=======
    namespace = "com.bengkelku"
>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.bengkel.bengkelku" // Ganti sesuai kebutuhan
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bengkelku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

<<<<<<< HEAD
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
=======
     signingConfigs {
        // Gunakan create("release") untuk membuat konfigurasi baru di KTS
        create("release") {
            if (keystorePropertiesFile.exists()) {
                // Gunakan '=' untuk assignment dan getProperty("...") untuk mengambil nilai
>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

<<<<<<< HEAD
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Optional: enable shrinking and obfuscation for release build
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
=======

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
>>>>>>> bed1c291bb024564a77edac7b1785e3c06ede87f
        }
    }
}

flutter {
    source = "../.."
}
