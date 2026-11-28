#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Flutter'ın KENDİ çizdiği String parametrelerini t() ile sarar.

Çalıştırma:
    python3 tools/i18n_wrap_params.py            # ne yapacağını yazar
    python3 tools/i18n_wrap_params.py --apply    # uygular

Neden gerekli: çeviri, Material'ın Text'ini gizleyip yerine çeviren bir
Text koymaya dayanıyor. Ama `hintText:`, `labelText:`, `semanticLabel:`,
`tooltip:` gibi parametreler Widget değil String alır; metni Flutter
kendi içinde çizer, bizim Text'imize hiç uğramaz. Bu yüzden oralardaki
Türkçe sessizce Türkçe kalır — simülatörde İngilizce arayüzde Türkçe
ipucu metinleri böyle görüldü.

Kapsam dışı bıraktıklarımız:
  * `label:` — bu projede çoğunlukla KENDİ widget'larımızın alanı
    (SectionFab, _Item, _Legend…). Onlar değeri bizim Text'imize
    veriyor, yani zaten çevriliyor. Flutter'ın NavigationDestination'ı
    gibi sayılı istisnalar elle düzeltildi.
  * Türkçe karakter içermeyen değerler (birim, kısaltma, sayı).
"""

from __future__ import annotations

import io
import os
import re
import sys

LIB = 'lib'
SKIP_DIR = os.path.join('core', 'i18n')
TR = set('çğıöşüÇĞİÖŞÜ')

# Flutter'ın kendi çizdiği String parametreleri.
PARAMS = [
    'hintText', 'labelText', 'helperText', 'errorText', 'counterText',
    'prefixText', 'suffixText', 'semanticLabel', 'semanticsLabel', 'tooltip',
]

LITERAL = r"'(?:[^'\\]|\\.)*'"

# Dart'ta yan yana yazılan dizgeler birleşir:
#     hintText: 'Kahvaltı: ...\n'
#         'Kaçınılacaklar: ...',
# Bunu tek parça saymazsak t() yalnız ilkini sarar ve dosya derlenmez.
PAT = re.compile(
    r"(?<![\w])(%s)(\s*:\s*)(%s(?:\s*%s)*)" % ('|'.join(PARAMS), LITERAL, LITERAL))

IMPORT_I18N = re.compile(r"import\s+'[^']*i18n/i18n\.dart'")
IMPORT_TEXT = re.compile(r"import\s+('[^']*i18n/text\.dart')\s*;")


def is_turkish(dart_literal: str) -> bool:
    return bool(set(dart_literal) & TR)


def add_import(src: str, path: str) -> str:
    """i18n.dart içe aktarmasını text.dart'ın yanına koyar."""
    if IMPORT_I18N.search(src):
        return src
    m = IMPORT_TEXT.search(src)
    if not m:
        raise SystemExit('%s: i18n/text.dart içe aktarması yok' % path)
    rel = m.group(1).replace('text.dart', 'i18n.dart')
    return src[:m.end()] + "\nimport %s;" % rel + src[m.end():]


def process(path: str, apply: bool) -> int:
    src = io.open(path, encoding='utf-8').read()

    # Yorum satırlarını kapsam dışında tutmak için maskele.
    masked = re.sub(r'//[^\n]*', lambda m: ' ' * len(m.group(0)), src)

    spans = []
    for m in PAT.finditer(masked):
        if not is_turkish(m.group(3)):
            continue
        spans.append((m.start(3), m.end(3), m.group(1), m.group(3)))

    if not spans:
        return 0

    out = src
    for start, end, name, lit in reversed(spans):
        out = out[:start] + 't(%s)' % lit + out[end:]
    out = add_import(out, path)

    if apply:
        io.open(path, 'w', encoding='utf-8').write(out)
    for _s, _e, name, lit in spans:
        print('  %-14s %s' % (name, lit[:58]))
    return len(spans)


def main():
    apply = '--apply' in sys.argv
    total = files = 0
    for root, _dirs, names in os.walk(LIB):
        if SKIP_DIR in root:
            continue
        for f in sorted(names):
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            p = os.path.join(root, f)
            n = process(p, apply)
            if n:
                print('%s (%d)' % (p, n))
                total += n
                files += 1
    print('%d dosyada %d parametre%s' %
          (files, total, ' sarıldı' if apply else ' sarılacak'))


if __name__ == '__main__':
    sys.exit(main())
