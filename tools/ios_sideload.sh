#!/usr/bin/env bash
#
# Ücretsiz Apple kimliğiyle iPhone'a kurar / yeniden kurar.
#
# Ücretsiz imza 7 GÜNDE BİR dolar ve uygulama açılmaz olur. Bu betik
# haftalık yeniden kurulumu tek komuta indirir:
#
#     tools/ios_sideload.sh
#
# Telefon USB ile bağlı ve kilidi açık olmalı. İlk kurulumdan sonra
# aynı Wi-Fi ağındaysa kablosuz da çalışır.
#
# İLK SEFERE ÖZEL (bir kez, Xcode'da):
#   1. open ios/Runner.xcworkspace
#   2. Runner hedefi > Signing & Capabilities > Team: kendi Apple kimliğin
#   3. Bir kez Xcode'dan çalıştır (provizyon profilini o oluşturur)
#   4. iPhone > Ayarlar > Genel > VPN ve Cihaz Yönetimi > geliştiriciye güven
#
# NOT: Ücretsiz kimlikle HealthKit ÇALIŞMAZ (Apple vermiyor). Uygulamanın
# geri kalanı normal çalışır; ölçümler elle girilir.

set -euo pipefail
cd "$(dirname "$0")/.."

# shellcheck source=/dev/null
[ -f tools/env.sh ] && source tools/env.sh >/dev/null 2>&1 || true

echo "Bağlı iPhone aranıyor…"
DEVICE_LINE="$(flutter devices --machine 2>/dev/null \
  | python3 -c '
import json, sys
try:
    devices = json.load(sys.stdin)
except Exception:
    devices = []
for d in devices:
    if d.get("targetPlatform", "").startswith("ios") and not d.get("emulator", True):
        sys.stdout.write(d["id"] + "\t" + d["name"])
        break
' || true)"

if [ -z "$DEVICE_LINE" ]; then
  echo
  echo "Bağlı bir iPhone bulunamadı."
  echo "  * Kabloyu tak, telefonun kilidini aç, 'Bu bilgisayara güven' de."
  echo "  * Simülatörde denemek için: flutter run -d <simulator>"
  exit 1
fi

DEVICE_ID="${DEVICE_LINE%%	*}"
DEVICE_NAME="${DEVICE_LINE##*	}"
echo "Cihaz: $DEVICE_NAME"
echo

# RELEASE şart. Debug derlemesi iOS 14+ ile ana ekrandan AÇILMAZ
# ("debug mode Flutter apps can only be launched from Flutter tooling")
# ve telefonda belirgin biçimde yavaş çalışır.
#
# `flutter install` derlemeyi ve imzalamayı kendisi yapar; ayrıca
# --no-codesign ile ön derleme yapmak işi iki kez yaptırıyordu.
# `flutter install` SADECE kurar, derlemez — önce imzalı bir release
# yapısı üretmek gerekiyor. (--no-codesign ile üretilen yapı kurulamaz:
# "Could not find application bundle at build/ios/iphoneos/Runner.app".)
echo "Release derleniyor (birkaç dakika sürebilir)…"
flutter build ios --release

echo "Telefona kuruluyor…"
flutter install --release -d "$DEVICE_ID"

echo
echo "Bitti. İmza 7 gün geçerli; süre dolunca bu betiği tekrar çalıştır."
