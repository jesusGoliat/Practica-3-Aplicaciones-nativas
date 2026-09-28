import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
    alias(libs.plugins.sqldelight)
}

kotlin {
    androidTarget {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    // iosX64 es el simulador en Mac Intel y en macOS virtualizado (x86_64);
    // iosSimulatorArm64 es el simulador en Mac con Apple Silicon.
    listOf(iosX64(), iosArm64(), iosSimulatorArm64()).forEach { destino ->
        destino.binaries.framework {
            baseName = "ComposeApp"
            isStatic = true
            // El driver nativo de SQLDelight usa la SQLite del sistema.
            linkerOpts("-lsqlite3")
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material3)
            implementation(compose.materialIconsExtended)
            implementation(compose.components.resources)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.sqldelight.coroutines)
        }
        androidMain.dependencies {
            implementation(compose.preview)
            implementation(libs.androidx.activity.compose)
            implementation(libs.kotlinx.coroutines.android)
            implementation(libs.sqldelight.android.driver)
        }
        iosMain.dependencies {
            implementation(libs.sqldelight.native.driver)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
        }
        // Las pruebas de commonMain se ejecutan en la JVM (Android unit tests)
        // con un driver SQLite de escritorio.
        val androidUnitTest by getting {
            dependencies { implementation(libs.sqldelight.sqlite.driver) }
        }
    }
}

sqldelight {
    databases {
        create("BaseGestor") {
            packageName.set("mx.ipn.escom.p3.gestor.bd")
        }
    }
}

android {
    namespace = "mx.ipn.escom.p3.gestor"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        applicationId = "mx.ipn.escom.p3.gestorkmp"
        minSdk = libs.versions.android.minSdk.get().toInt()
        targetSdk = libs.versions.android.targetSdk.get().toInt()
        versionCode = 1
        versionName = "1.0"
    }
    packaging {
        resources { excludes += "/META-INF/{AL2.0,LGPL2.1}" }
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            // Firmado con la llave de depuración para poder instalar el APK de la entrega.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

compose.resources {
    packageOfResClass = "mx.ipn.escom.p3.gestor.recursos"
}
