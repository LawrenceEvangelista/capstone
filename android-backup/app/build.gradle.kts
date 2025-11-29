plugins {
    id("com.android.application") version "8.9.0"
    id("org.jetbrains.kotlin.android") version "2.1.0"
    id("com.google.gms.google-services")    
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.testapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.testapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true

            // Proguard rules for release
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            consumerProguardFiles("proguard-rules.pro")

            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Avoid duplicate metadata issues
    packaging {
        resources.excludes.add("META-INF/*")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM (Recommended)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // Firebase Core + Services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-database")

    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")

    // Multidex
    implementation("androidx.multidex:multidex:2.0.1")
}
