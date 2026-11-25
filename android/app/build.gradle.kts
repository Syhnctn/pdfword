import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}


android {
    namespace = "com.pdfword.pro.pdfword_pro"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pdfword.pro.pdfword_pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 16 KB page size support.
    //
    // Play requires every native library to be 16 KB aligned so the app can run on
    // 16 KB devices (Android 15+/16). Two things are needed:
    //   1. ndkVersion = flutter.ndkVersion -> NDK r28+, which emits 16 KB aligned ELFs.
    //      Already set above (Flutter 3.41.1 pins 28.2.13676358).
    //   2. AGP 8.5.1+ (we use 8.11.1) automatically zip-aligns uncompressed .so entries
    //      inside the APK when extractNativeLibs is false, which is the default for
    //      minSdk >= 23. We keep that default (do not set extractNativeLibs).
    // The verifyPageSize16Kb task below fails the build if a shipped .so is only 4 KB
    // aligned, so a future dependency downgrade cannot silently reintroduce this.

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
            }
            val storeTypeProp = keystoreProperties.getProperty("storeType")
            if (!storeTypeProp.isNullOrBlank()) {
                storeType = storeTypeProp
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 / resource shrinking. AGP 8.x enables R8 "full mode" by default,
            // which is what the Play Console "R8 optimizasyonu" recommendation asks for.
            // Keep rules live in proguard-rules.pro; they are required by the
            // reflection-based plugin code (google_mobile_ads, supabase, open_filex...).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

        }
    }

    // Pin androidx.datastore, which arrives transitively via shared_preferences_android.
    // It ships libdatastore_shared_counter.so, the exact library Play flagged in the
    // 16 KB page size report. 1.2.0 is the 16 KB aligned build; pinning it guards
    // against a transitive downgrade reintroducing the 4 KB only variant.
    dependencies {
        implementation("androidx.datastore:datastore:1.2.0")
    }
}

flutter {
    source = "../.."
}

// 16 KB page size verification (kept in a separate plain Groovy script for clarity).
apply(from = "page-size-check.gradle")

