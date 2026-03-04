plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Conditionally apply Google Services plugin if google-services.json exists and package matches
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    try {
        val jsonContent = googleServicesFile.readText()
        // Simple string check: if the JSON contains the current package name, apply the plugin
        // This avoids JSON parsing complexity in Gradle Kotlin DSL
        if (jsonContent.contains("\"package_name\":\"com.batkt.workease\"")) {
            apply(plugin = "com.google.gms.google-services")
        } else {
            println("Warning: google-services.json exists but doesn't contain package 'com.batkt.workease'. Skipping Google Services plugin.")
        }
    } catch (e: Exception) {
        // If reading fails, don't apply the plugin
        println("Warning: Could not read google-services.json: ${e.message}")
    }
}

android {
    namespace = "com.batkt.workease"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.batkt.workease"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Shrink code and resources for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
