// ─────────────────────────────────────────────────────────────────────────────
// AutoLoan — Android build configuration (Android-first)
// iOS equivalent: ios/Runner.xcodeproj — NOT configured yet
// TODO: iOS — create Runner targets ca / au / us (Xcode schemes)
// TODO: iOS — set PRODUCT_BUNDLE_IDENTIFIER per target:
//             ca → com.autoloan.ca.calculator
//             uk → com.autoloan.uk.calculator
//             us → com.autoloan.us.calculator
// TODO: iOS — add GADApplicationIdentifier to each Info.plist
// TODO: iOS — add NSUserTrackingUsageDescription for ATT (iOS 14+)
// ─────────────────────────────────────────────────────────────────────────────
import java.util.Base64
import java.util.Properties

// ── Flavor → dart-define injection ───────────────────────────────────────────
// String.fromEnvironment('FLAVOR') in Dart reads --dart-define, NOT buildConfigField.
// Detect the active flavor from Gradle task names and set dart-defines early.
val activeFlavor: String = run {
    val tasks = gradle.startParameter.taskNames.joinToString(" ").lowercase()
    when {
        tasks.contains("uk") -> "uk"
        tasks.contains("us") -> "us"
        else                 -> "ca"
    }
}
val encodedDefine = Base64.getEncoder().encodeToString("FLAVOR=$activeFlavor".toByteArray())
project.extra["dart-defines"] = encodedDefine

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("dev.flutter.flutter-gradle-plugin")
}

// Read signing properties
val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) keystoreProperties.load(keystoreFile.inputStream())

// Read local properties (admob IDs etc.)
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
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    flavorDimensions += "country"

    productFlavors {
        create("ca") {
            dimension = "country"
            applicationId = "com.autoloan.ca.calculator"
            resValue("string", "app_name", "Auto Loan Canada")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.ca", "ca-app-pub-3940256099942544~3347511713")
        }
        create("uk") {
            dimension = "country"
            applicationId = "com.autoloan.uk.calculator"
            resValue("string", "app_name", "Auto Loan UK")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.uk", "ca-app-pub-3940256099942544~3347511713")
        }
        create("us") {
            dimension = "country"
            applicationId = "com.autoloan.us.calculator"
            resValue("string", "app_name", "Auto Loan USA")
            manifestPlaceholders["admobAppId"] =
                localProps.getProperty("admob.appId.us", "ca-app-pub-3940256099942544~3347511713")
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias      = keystoreProperties["keyAlias"]      as String
            keyPassword   = keystoreProperties["keyPassword"]   as String
            storeFile     = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        debug {
            // Each flavor uses its test google-services.json
        }
        release {
            signingConfig = signingConfigs.getByName("release")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
}
