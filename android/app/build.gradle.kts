plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.store_locator"
compileSdk=36

defaultConfig {
        applicationId = "com.example.store_locator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }



    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
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
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.0")
    implementation("com.android.support:multidex:1.0.3")
}
