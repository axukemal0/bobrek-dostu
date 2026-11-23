#!/bin/zsh
# Böbrek Dostu — geliştirme ortamı değişkenleri.
#
# Kullanım:
#   source tools/env.sh
#
# Kalıcı yapmak için bu dosyadaki satırları ~/.zshrc'ye ekle.
#
# Araçların kurulu olduğu yer (bkz. README bölüm 2):
#   ~/development/flutter      Flutter SDK (stable 3.50.1)
#   ~/development/jdk17        Temurin JDK 17
#   ~/development/android-sdk  Android cmdline-tools + platform + build-tools

export JAVA_HOME="$HOME/development/jdk17"
export ANDROID_HOME="$HOME/development/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/development/flutter/bin:$PATH"

echo "Flutter: $(command -v flutter || echo BULUNAMADI)"
echo "Java:    $(command -v java || echo BULUNAMADI)"
echo "Android: $ANDROID_HOME"
