#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""i18n/<kod>.json dosyalarından Dart sözlüklerini üretir.

Çalıştırma:
    python3 tools/i18n_build.py

Gerçeğin kaynağı JSON dosyalarıdır; `lib/core/i18n/translations/*.dart`
ÜRETİLMİŞ dosyalardır, elle değiştirilmez.

JSON biçimi — anahtar kaynaktaki Türkçe metin, değer çevirisi:
    { "Kaydet": "Save", "Tahlil ekle": "Add lab result" }

Değeri boş ya da Türkçesiyle aynı olan satırlar üretime ALINMAZ: sözlükte
yer kaplamasınlar, zaten çeviri yoksa metnin kendisi gösteriliyor.
"""

from __future__ import annotations

import io
import json
import os
import sys

LANGS = ['en', 'es', 'ar', 'fr', 'de', 'ru', 'pt', 'hi', 'zh']
SRC = 'i18n'
OUT = 'lib/core/i18n/translations'


def dart_string(s: str) -> str:
    """Dart tek tırnaklı dizge değişmezi üretir."""
    out = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    out = out.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
    return "'" + out + "'"


def build(code: str) -> int:
    path = os.path.join(SRC, '%s.json' % code)
    if not os.path.exists(path):
        data = {}
    else:
        data = json.load(io.open(path, encoding='utf-8'))

    rows = []
    for key in sorted(data):
        value = data[key]
        if not isinstance(value, str):
            continue
        if not value.strip() or value == key:
            continue
        rows.append('  %s: %s,' % (dart_string(key), dart_string(value)))

    body = '\n'.join(rows)
    text = (
        '// ÜRETİLMİŞ DOSYA — elle değiştirme.\n'
        '// Kaynak: %s   Üretici: tools/i18n_build.py\n'
        '// Anahtar, kaynaktaki Türkçe metnin çalışma zamanındaki değeridir.\n'
        '\n'
        'const Map<String, String> table = <String, String>{\n'
        '%s\n'
        '};\n'
    ) % (path, body) if rows else (
        '// ÜRETİLMİŞ DOSYA — elle değiştirme.\n'
        '// Kaynak: %s   Üretici: tools/i18n_build.py\n'
        'const Map<String, String> table = <String, String>{};\n'
    ) % path

    io.open(os.path.join(OUT, '%s.dart' % code), 'w', encoding='utf-8').write(text)
    return len(rows)


def main():
    total = 0
    for code in LANGS:
        n = build(code)
        total += n
        print('%-3s %5d satır' % (code, n))
    print('toplam %d çeviri' % total)


if __name__ == '__main__':
    sys.exit(main())
