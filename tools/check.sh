#!/bin/zsh
# Tam doğrulama: analiz + testler + hata ayıklama APK'sı.
set -e
cd "$(dirname "$0")/.."
source tools/env.sh

echo "\n=== flutter pub get ==="
flutter pub get

echo "\n=== kod üretimi (drift) ==="
dart run build_runner build

echo "\n=== statik analiz ==="
flutter analyze

echo "\n=== testler ==="
flutter test

echo "\n=== hata ayıklama APK'sı ==="
flutter build apk --debug

echo "\nAPK: $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
