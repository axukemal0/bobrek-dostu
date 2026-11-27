#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Çevrilecek metinleri sıralı parçalara böler ve geri birleştirir.

    python3 tools/i18n_batches.py split     # i18n/batches/NN-source.json
    python3 tools/i18n_batches.py merge     # i18n/<kod>.json
    python3 tools/i18n_batches.py status    # ne kadarı çevrildi

Neden parça parça: 1.795 metin var ve dokuz dile çevrilecek. Tek
hamlede yapılamaz; her parça bitince diske yazılır, iş yarıda kalırsa
yapılanlar durur.

SIRA ÖNEMLİ: önce her ekranda görünen ortak metinler (gezinme,
düğmeler, ayarlar), en son klinik metinler. Yarım kalırsa elde
kullanılabilir bir uygulama olsun — tersi olsaydı menüler Türkçe,
klinik notlar başka dilde kalırdı.
"""

from __future__ import annotations

import io
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from i18n_scan import scan  # noqa: E402

LANGS = ['en', 'es', 'ar', 'fr', 'de', 'ru', 'pt', 'hi', 'zh']
BATCH_DIR = os.path.join('i18n', 'batches')
CHARS_PER_BATCH = 5200

# Küçük sayı = önce çevrilir.
PRIORITY = [
    ('lib/core/widgets/', 0),
    ('lib/core/theme/', 0),
    ('lib/features/home/', 1),
    ('lib/features/settings/', 2),
    ('lib/features/onboarding/', 3),
    ('lib/features/nutrition/', 4),
    ('lib/features/medications/', 4),
    ('lib/features/fluid/', 4),
    ('lib/features/labs/', 5),
    ('lib/features/weight/', 5),
    ('lib/features/health/', 5),
    ('lib/features/calendar/', 6),
    ('lib/features/emergency/', 6),
    ('lib/features/report/', 6),
    ('lib/features/places/', 7),
    ('lib/features/travel/', 7),
    ('lib/features/reading/', 7),
    ('lib/features/ai/', 7),
    ('lib/core/services/', 8),
    ('lib/clinical/', 9),
]


def rank(site: str) -> int:
    for prefix, value in PRIORITY:
        if site.startswith(prefix):
            return value
    return 10


def ordered_sources():
    found = scan()
    rows = []
    for value, rec in found.items():
        if rec['interpolated']:
            continue
        first = rec['sites'][0]
        rows.append((rank(first), first, value))
    rows.sort(key=lambda r: (r[0], r[1], r[2]))
    return [r[2] for r in rows]


def split():
    os.makedirs(BATCH_DIR, exist_ok=True)
    sources = ordered_sources()
    batch, size, index = [], 0, 1
    written = 0

    def flush(batch, index):
        path = os.path.join(BATCH_DIR, '%02d-source.json' % index)
        io.open(path, 'w', encoding='utf-8').write(
            json.dumps(batch, ensure_ascii=False, indent=1)
        )
        print('%s  %3d metin  %5d karakter' % (
            path, len(batch), sum(len(s) for s in batch)))

    for s in sources:
        batch.append(s)
        size += len(s)
        if size >= CHARS_PER_BATCH:
            flush(batch, index)
            written += len(batch)
            batch, size, index = [], 0, index + 1
    if batch:
        flush(batch, index)
        written += len(batch)
    print('%d metin, %d parça' % (written, index))


def merge():
    tables = {code: {} for code in LANGS}
    for name in sorted(os.listdir(BATCH_DIR)):
        if not name.endswith('.json') or name.endswith('-source.json'):
            continue
        data = json.load(io.open(os.path.join(BATCH_DIR, name), encoding='utf-8'))
        for code, rows in data.items():
            if code not in tables:
                continue
            for key, value in rows.items():
                if isinstance(value, str) and value.strip():
                    tables[code][key] = value
    for code in LANGS:
        path = os.path.join('i18n', '%s.json' % code)
        io.open(path, 'w', encoding='utf-8').write(
            json.dumps(tables[code], ensure_ascii=False, indent=1, sort_keys=True)
        )
        print('%-3s %5d çeviri -> %s' % (code, len(tables[code]), path))


def verbatim() -> set:
    """Her dilde AYNI kalan metinler.

    Kılavuz adları (KDOQI 2020, ACC/AHA 2017), ürün adları ve biçim
    örnekleri (sk-ant-...) çevrilmez. Çevirisi olmayan metin zaten
    kendisi olarak gösterildiği için sözlüğe yazılmazlar; burada
    listelenmeleri yalnızca "eksik çeviri" sayılmamaları içindir.
    """
    path = os.path.join('i18n', 'verbatim.json')
    if not os.path.exists(path):
        return set()
    return set(json.load(io.open(path, encoding='utf-8')))


def status():
    sources = ordered_sources()
    keep = verbatim()
    sources = [s for s in sources if s not in keep]
    total = len(sources)
    print('çevrilecek metin: %d' % total)
    for code in LANGS:
        path = os.path.join('i18n', '%s.json' % code)
        done = 0
        if os.path.exists(path):
            data = json.load(io.open(path, encoding='utf-8'))
            done = sum(1 for s in sources if data.get(s))
        bar = '#' * (done * 30 // max(total, 1))
        print('%-3s %5d/%d  %-30s %3d%%' % (
            code, done, total, bar, done * 100 // max(total, 1)))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'status'
    {'split': split, 'merge': merge, 'status': status}[cmd]()


if __name__ == '__main__':
    sys.exit(main())
