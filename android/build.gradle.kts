//  Flutter 安卓项目根级 Gradle 配置（官方标准，绝对稳定）
plugins {
    id("com.android.application") version "7.4.2" apply false
    id("com.android.library") version "7.4.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.withType<Delete> {
    delete(rootProject.layout.buildDirectory)
}