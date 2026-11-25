allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Android Lint'i tüm alt projelerde kapat.
//
// Sebep: AGP ile birlikte gelen lint sürümü, image_picker_android içindeki
// bir Java dosyasının javadoc yorumunu ayrıştırırken kendi içinde
// çöküyor (NoSuchMethodError: JavaDocParser.parseDataItem) ve
// `:image_picker_android:lintVitalAnalyzeRelease` görevi release
// derlemesini komple durduruyor. Hata bizim kodumuzda değil, lint'in
// kendisinde; eklentinin kaynağına da dokunamıyoruz.
//
// Lint APK üretmek için gerekli değildir — yalnız statik denetim yapar.
// Kendi Dart kodumuz zaten `flutter analyze` ile denetleniyor.
// Üst akışta düzelince bu blok kaldırılabilir.
subprojects {
    tasks.configureEach {
        if (name.startsWith("lint")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
