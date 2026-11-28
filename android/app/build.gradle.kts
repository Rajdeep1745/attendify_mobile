import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseApplicationId = providers.gradleProperty("ATTENDIFY_APPLICATION_ID").orNull
val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }
val releaseSigningReady = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !signingProperties.getProperty(it).isNullOrBlank() }
val configuredApiUrl = rootProject.file("../.env").takeIf { it.exists() }
    ?.readLines()
    ?.firstOrNull { it.trimStart().startsWith("API_BASE_URL=") }
    ?.substringAfter('=')
    ?.trim()

android {
    namespace = "com.example.attendance_app"
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
        applicationId = releaseApplicationId ?: "com.example.attendance_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningReady) signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Development builds remain usable; distribution must never silently use debug signing.
tasks.matching { it.name in listOf("validateSigningRelease", "packageRelease", "bundleRelease") }.configureEach {
    doFirst {
        check(!releaseApplicationId.isNullOrBlank() && releaseApplicationId != "com.example.attendance_app") {
            "Set ATTENDIFY_APPLICATION_ID in your private Gradle properties before releasing."
        }
        check(releaseSigningReady) { "Configure android/key.properties with your release signing key." }
    }
}
