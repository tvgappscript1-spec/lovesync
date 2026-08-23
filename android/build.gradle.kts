// Dong bo compileSdk cho MOI module plugin.
// Nhieu plugin (geocoding_android, geolocator_android...) hardcode compileSdk thap hon,
// gay loi "requires compileSdk 36 or later". Khoi nay phai dat TRUOC evaluationDependsOn,
// neu khong Gradle bao "project is already evaluated".
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val ext = project.extensions.findByName("android")
            if (ext != null) {
                try {
                    ext.javaClass
                        .getMethod("setCompileSdkVersion", String::class.java)
                        .invoke(ext, "android-36")
                    println("LOVESYNC compileSdk=36 -> " + project.name)
                } catch (e: Exception) {
                    println("LOVESYNC bo qua " + project.name + ": " + e.message)
                }
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
