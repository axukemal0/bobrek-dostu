#!/usr/bin/env bash
# Yazı tiplerini Latin + Türkçe kümesine indirger.
#
# Gömülü yazı tipleri uygulamanın en büyük varlıklarıydı (972 KB).
# Uygulama Türkçe; Kiril, Yunan, Vietnamca vb. alt kümelere gerek yok.
# Eksik bir glif denk gelirse Flutter sistem yazı tipine düşer — tofu
# kutusu çıkmaz, yalnız o karakter farklı görünür.
#
# Kullanım:  pip install fonttools brotli && tools/subset_fonts.sh
set -euo pipefail

UNICODES="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2010-2027,U+2030-205E,\
U+2070-209F,U+20A0-20BF,U+2122,U+2248,U+2260,U+2264,U+2265,U+25CF,U+2713"

cd "$(dirname "$0")/.."
for f in assets/fonts/*.ttf; do
  pyftsubset "$f" --unicodes="$UNICODES" --layout-features='*' \
    --output-file="$f.sub"
  mv "$f.sub" "$f"
  echo "$(basename "$f"): $(( $(stat -f%z "$f") / 1024 )) KB"
done
