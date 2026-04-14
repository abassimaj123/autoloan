// ─────────────────────────────────────────────────────────────────────────────
// AutoLoan — Android build configuration (Android-first)
// iOS equivalent: ios/Runner.xcodeproj — NOT configured yet
// TODO: iOS — create Runner targets ca / au / us (Xcode schemes)
// TODO: iOS — set PRODUCT_BUNDLE_IDENTIFIER per target:
//             ca → com.autoloan.canada
//             uk → com.autoloan.uk
//             us → com.autoloan.usa
// TODO: iOS — add GADApplicationIdentifier to each Info.plist
// TODO: iOS — add NSUserTrackingUsageDescription for ATT (iOS 14+)
// ─────────────────────────────────────────────────────────────────────────────
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("dev.flutter.flutter-gradle-plugin")
}

// Read signing properties
val localProps = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) localPropsFile.inputStream().use { localProps.load(it) }

android {
    namespace = "com.autoloan.auto_loan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    flavorDimensions += "country"

    productFlavors {
        create("ca") {
            dimension = "country"
            applicationId = "com.autoloan.canada"
            resValue("string", "app_name", "Auto Loan Canada")
            buildConfigField("String", "FLAVOR", "\"ca\"")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.ca", "ca-app-pub-3940256099942544~3347511713")
        }
        create("uk") {
            dimension = "country"
            applicationId = "com.autoloan.uk"
            resValue("string", "app_name", "Auto Loan UK")
            buildConfigField("String", "FLAVOR", "\"uk\"")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.uk", "ca-app-pub-3940256099942544~3347511713")
        }
        create("us") {
            dimension = "country"
            applicationId = "com.autoloan.usa"
            resValue("string", "app_name", "Auto Loan USA")
            buildConfigField("String", "FLAVOR", "\"us\"")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.us", "ca-app-pub-3940256099942544~3347511713")
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = localProps.getProperty("storeFile")?.let { file(it) }
            storePassword = localProps.getProperty("storePassword")
            keyAlias = localProps.getProperty("keyAlias")
            keyPassword = localProps.getProperty("keyPassword")
        }
    }

    buildTypes {
        debug {
            // Each flavor uses its test google-services.json
        }
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
}
