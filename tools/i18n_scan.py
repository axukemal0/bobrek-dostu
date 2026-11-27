#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Uygulamadaki kullanıcıya görünen Türkçe metinleri bulur.

Çalıştırma:
    python3 tools/i18n_scan.py            # özet
    python3 tools/i18n_scan.py --json out.json

Neden bir tarayıcı var: metinler 80'den fazla dosyaya dağılmış durumda ve
çoğu satıra sığmadığı için bitişik parçalara bölünmüş
("bir satır " 'ikinci satır'). Elle toplamak hem eksik kalır hem de her
metin değişikliğinde yeniden eksilir. Bu betik Dart kaynağını sözcüklerine
ayırır, yorumları atar, bitişik dizgeleri BİRLEŞTİRİR ve dizgenin hangi
bağlamda geçtiğine bakarak kullanıcıya görünüp görünmediğine karar verir.

Çıktı: her metin için kaynak değeri, geçtiği yerler ve ara değer (`$`)
içerip içermediği.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys

LIB = 'lib'

# Dizgenin kullanıcıya göründüğüne işaret eden bağlamlar. Dizgenin HEMEN
# öncesindeki metne bakılır.
WIDGET_CALL = re.compile(r'\bText\s*\(\s*$')
NAMED_ARG = re.compile(
    r'\b('
    r'label|title|message|subtitle|semanticLabel|hint|hintText|labelText|'
    r'helperText|helpText|tooltip|errorText|text|labelTr|messageTr|nameTr|'
    r'reasonTr|noteTr|summaryTr|descriptionTr|unitTr|headline|body|caption|'
    r'confirmLabel|cancelLabel|okLabel|emptyTitle|emptyMessage|placeholder'
    r')\s*:\s*$'
)
T_CALL = re.compile(r'\bt\s*\(\s*$')
TF_CALL = re.compile(r'\btf\s*\(\s*$')

# Kesinlikle metin OLMAYAN dizgeler: varlık yolları, anahtarlar, biçim
# dizgeleri, kanal adları.
NOT_TEXT = re.compile(
    r'^(assets/|lib/|package:|https?://|com\.|android\.|ios\.|[a-z_]+/[a-z_]+$)'
)

TURKISH = set('çğıöşüÇĞİÖŞÜâîû')


_ESCAPES = {
    'n': '\n', 't': '\t', 'r': '\r', 'b': '\b', 'f': '\f', 'v': '\v',
    '0': '\0', '\\': '\\', "'": "'", '"': '"', '$': '$',
}


def unescape(s: str) -> str:
    """Dart kaçış dizilerini çözer.

    ÖNEMLİ: katalog anahtarı ÇALIŞMA ZAMANINDAKİ değer olmalı. Kaynakta
    `112\\'yi ARA` yazan dizge çalışırken `112'yi ARA` olur; kaçışları
    çözmezsek sözlük hiçbir zaman eşleşmez.
    """
    out = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c != '\\' or i + 1 >= n:
            out.append(c)
            i += 1
            continue
        nxt = s[i + 1]
        if nxt == 'u':
            if i + 2 < n and s[i + 2] == '{':
                j = s.find('}', i + 3)
                if j > 0:
                    out.append(chr(int(s[i + 3:j], 16)))
                    i = j + 1
                    continue
            else:
                out.append(chr(int(s[i + 2:i + 6], 16)))
                i += 6
                continue
        if nxt == 'x':
            out.append(chr(int(s[i + 2:i + 4], 16)))
            i += 4
            continue
        out.append(_ESCAPES.get(nxt, nxt))
        i += 2
    return ''.join(out)


def strip_and_scan(src: str):
    """Kaynaktaki dizge değişmezlerini (yorumlar hariç) sırayla verir.

    Döndürülen her öğe: (başlangıç, bitiş, değer, ham_mı, ara_değerli_mi)
    Üç tırnaklı ve ham (r'') dizgeler de tanınır.
    """
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]

        # satır yorumu
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            j = src.find('\n', i)
            i = n if j < 0 else j + 1
            continue

        # blok yorumu (iç içe olabilir — Dart'ta geçerlidir)
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            depth = 1
            i += 2
            while i < n and depth:
                if src.startswith('/*', i):
                    depth += 1
                    i += 2
                elif src.startswith('*/', i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            continue

        if c in '\'"':
            raw = i > 0 and src[i - 1] == 'r'
            start = i - 1 if raw else i
            triple = src.startswith(c * 3, i)
            quote = c * 3 if triple else c
            i += len(quote)
            buf = []
            interpolated = False
            while i < n:
                if not raw and src[i] == '\\':
                    buf.append(src[i:i + 2])
                    i += 2
                    continue
                if src[i] == '$':
                    interpolated = True
                    # ${...} içindeki tırnakları yutma
                    if i + 1 < n and src[i + 1] == '{':
                        depth = 1
                        j = i + 2
                        while j < n and depth:
                            if src[j] == '{':
                                depth += 1
                            elif src[j] == '}':
                                depth -= 1
                            j += 1
                        buf.append(src[i:j])
                        i = j
                        continue
                if src.startswith(quote, i):
                    i += len(quote)
                    break
                buf.append(src[i])
                i += 1
            out.append((start, i, ''.join(buf), raw, interpolated))
            continue

        i += 1
    return out


def merge_adjacent(lits, src):
    """Bitişik dizgeleri (Dart'ta otomatik birleşirler) tek parça yapar."""
    merged = []
    k = 0
    while k < len(lits):
        start, end, val, raw, interp = lits[k]
        pieces = [val]
        last_end = end
        while k + 1 < len(lits):
            gap = src[last_end:lits[k + 1][0]]
            if gap.strip() != '':
                break
            k += 1
            pieces.append(lits[k][2])
            interp = interp or lits[k][4]
            last_end = lits[k][1]
        joined = ''.join(pieces)
        merged.append(
            (start, last_end, joined if raw else unescape(joined), raw, interp)
        )
        k += 1
    return merged


def context_before(src: str, pos: int) -> str:
    """Dizgeden önceki, boşlukları sadeleştirilmiş kısa bağlam."""
    head = src[max(0, pos - 120):pos]
    return re.sub(r'\s+', ' ', head)


def looks_user_facing(value: str, ctx: str) -> bool:
    if len(value.strip()) < 2:
        return False
    if NOT_TEXT.match(value.strip()):
        return False
    if not any(ch.isalpha() for ch in value):
        return False
    tail = ctx.rstrip()
    # Bağlam eşleşmesi için sondaki boşluk önemli: "Text(" ya da "label:"
    probe = ctx
    if WIDGET_CALL.search(probe) or T_CALL.search(probe) or TF_CALL.search(probe):
        return True
    if NAMED_ARG.search(probe):
        return True
    # Türkçe harf içeren uzun cümleler bağlamdan bağımsız olarak adaydır.
    if any(ch in TURKISH for ch in value) and len(value) > 3:
        return True
    # Türkçe harfi olmayan ama cümle gibi duranlar (ör. "Tamam")
    if len(value.split()) >= 2 and value[0].isupper() and tail.endswith(('(', ':', ',')):
        return True
    return False


def scan():
    found = {}
    for root, _dirs, files in os.walk(LIB):
        for f in sorted(files):
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            path = os.path.join(root, f)
            src = io.open(path, encoding='utf-8').read()
            lits = merge_adjacent(strip_and_scan(src), src)
            for start, _end, val, raw, interp in lits:
                if raw:
                    continue
                ctx = context_before(src, start)
                if not looks_user_facing(val, ctx):
                    continue
                line = src.count('\n', 0, start) + 1
                rec = found.setdefault(
                    val, {'value': val, 'interpolated': interp, 'sites': []}
                )
                rec['interpolated'] = rec['interpolated'] or interp
                rec['sites'].append('%s:%d' % (path, line))
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--json')
    args = ap.parse_args()

    found = scan()
    plain = {k: v for k, v in found.items() if not v['interpolated']}
    interp = {k: v for k, v in found.items() if v['interpolated']}

    print('kullanıcıya görünen metin : %d' % len(found))
    print('  düz (ara değersiz)      : %d' % len(plain))
    print('  ara değerli ($ içeren)  : %d' % len(interp))
    chars = sum(len(k) for k in plain)
    print('  düz metinlerin uzunluğu : %d karakter' % chars)

    if args.json:
        io.open(args.json, 'w', encoding='utf-8').write(
            json.dumps(
                {
                    'plain': sorted(plain),
                    'interpolated': sorted(interp),
                    'sites': {k: v['sites'] for k, v in found.items()},
                },
                ensure_ascii=False,
                indent=1,
            )
        )
        print('yazıldı: %s' % args.json)


if __name__ == '__main__':
    sys.exit(main())
