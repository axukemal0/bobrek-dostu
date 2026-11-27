#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ara değerli metinleri çevrilebilir şablona dönüştürür.

Çalıştırma:
    python3 tools/i18n_templates.py            # ne yapacağını yazar
    python3 tools/i18n_templates.py --apply    # uygular

`'$sent kişiye SMS gönderildi.'`  ->  `tf('{0} kişiye SMS gönderildi.', [sent])`

NEDEN GEREKLİ: çeviri, metnin ÇALIŞMA ZAMANINDAKİ değerine bakıyor.
Ara değerli bir metnin değeri her seferinde farklıdır ("3 kişiye…",
"1 kişiye…"), yani sözlükte hiçbir zaman eşleşmez. Şablona çevrilince
değişmeyen kısım anahtar olur, sayılar yerine konur.

Yer tutucular NUMARALIDIR ({0}, {1}). Diller sözdizimini farklı sıralar;
çevirmen sırayı değiştirebilmeli.

NEYİ ATLAR:
  * Yapay zeka istem metinleri — bunlar Claude'a gidiyor, arayüzde
    görünmüyor. Cevabın dili istemin sonuna eklenen tek satırla
    ayarlanıyor (bkz. lib/core/services/ai_prompts.dart).
  * Sadece yer tutucu + birim olanlar: '${q.ml} mL', '$a/$b mmHg.'
    Çevrilecek bir şey yok; sözlüğü şişirirler.
  * Ham dizgeler (r'...') ve hata ayıklama metinleri ('$e', '$value').
"""

from __future__ import annotations

import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from i18n_scan import (  # noqa: E402
    LIB, context_before, looks_user_facing, merge_adjacent, strip_and_scan,
    unescape, TURKISH,
)

# Yapay zeka istemleri arayüz metni değildir.
SKIP_FILES = {
    os.path.join('lib', 'core', 'services', 'ai_prompts.dart'),
    # Veritabanı katmanında SQL ve SQLCipher komutları var. Bir çevirmenin
    # (ya da bir makinenin) `PRAGMA key = '{0}'` satırına dokunması
    # veritabanını açılamaz hâle getirir.
    os.path.join('lib', 'core', 'db', 'database.dart'),
}

PLACEHOLDER = re.compile(r'\{\d+\}')

# Çeviriye kesinlikle girmemesi gereken içerikler: SQL, adresler, komutlar.
# Bunlar sözlüğe girerse bir çeviri hatası işlevi bozar, görünüşü değil.
DANGEROUS = re.compile(
    r'PRAGMA|SELECT\s|INSERT\s|UPDATE\s|DELETE\s|CREATE\s|https?://|'
    r'^\s*\[out:|package:|content://|file://'
    # Düzenli ifade kalıpları. Bir çevirmenin `(?<![a-zçğıöşü])` içine
    # dokunması, etiket okuyucuyu sessizce bozar.
    r'|\(\?[:<!=]|\[\^|\[a-z|\\\\[dswbDSWB]|\{\d+,\d*\}',
    re.I,
)


def parse_interpolated(span: str):
    """Bitişik dizge dizisini (şablon, [ifade kaynakları]) yapar.

    Şablonda ara değerlerin yerine {0}, {1} … konur; kaçışlar çözülür,
    yani şablon ÇALIŞMA ZAMANINDAKİ metindir.
    """
    parts = []
    exprs = []
    i = 0
    n = len(span)
    while i < n:
        c = span[i]
        if c not in '\'"':
            # dizgeler arası boşluk / 'r' öneki
            if c == 'r':
                return None  # ham dizge: dokunma
            i += 1
            continue

        triple = span.startswith(c * 3, i)
        quote = c * 3 if triple else c
        i += len(quote)
        while i < n:
            if span[i] == '\\':
                parts.append(unescape(span[i:i + 2]))
                i += 2
                continue
            if span[i] == '$':
                if i + 1 < n and span[i + 1] == '{':
                    depth = 1
                    j = i + 2
                    while j < n and depth:
                        if span[j] == '{':
                            depth += 1
                        elif span[j] == '}':
                            depth -= 1
                        j += 1
                    exprs.append(span[i + 2:j - 1])
                    parts.append('{%d}' % (len(exprs) - 1))
                    i = j
                    continue
                m = re.match(r'\$([A-Za-z_][A-Za-z0-9_]*)', span[i:])
                if m:
                    exprs.append(m.group(1))
                    parts.append('{%d}' % (len(exprs) - 1))
                    i += m.end()
                    continue
            if span.startswith(quote, i):
                i += len(quote)
                break
            parts.append(span[i])
            i += 1
    return ''.join(parts), exprs


def worth_translating(template: str) -> bool:
    """Şablonda çevrilecek GERÇEK metin var mı?

    Yer tutucular çıkarıldıktan sonra geriye en az iki sözcük ya da bir
    Türkçe harf kalmalı. Böylece '$a/$b mmHg.' ve '${x} mL' elenir,
    '$m dk önce' ve '$sent kişiye SMS gönderildi.' kalır.
    """
    if DANGEROUS.search(template):
        return False
    rest = PLACEHOLDER.sub(' ', template)
    words = [w for w in re.findall(r'[^\W\d_]{2,}', rest, re.UNICODE)]
    if not words:
        return False
    if any(ch in TURKISH for ch in rest):
        return True
    return len(words) >= 2 and sum(len(w) for w in words) >= 8


def dart_string(s: str) -> str:
    return "'" + (
        s.replace('\\', '\\\\')
        .replace("'", "\\'")
        .replace('$', '\\$')
        .replace('\n', '\\n')
        .replace('\r', '\\r')
        .replace('\t', '\\t')
    ) + "'"


def render_call(template: str, exprs: list, column: int) -> str:
    """`tf(...)` çağrısını üretir, gerekirse satırlara bölerek.

    Bu depo `dart format`'ın ESKİ biçimiyle yazılmış; dosyaları yeni
    biçimlendiriciden geçirmek 3.000 satırlık alakasız bir fark üretiyor.
    O yüzden biçimlendirici çalıştırılmaz ve uzun çağrılar burada elle
    bölünür: kaynak 80 sütunda kalsın.
    """
    args = ', '.join(exprs)
    single = 'tf(%s, [%s])' % (dart_string(template), args)
    if column + len(single) <= 78 and '\n' not in template:
        return single

    indent = ' ' * column
    chunks = []
    line = ''
    for word in template.split(' '):
        candidate = word if not line else line + ' ' + word
        # Satır sonlarından sonra parçayı kes: okunurluk için.
        if len(candidate) > 52 and line:
            chunks.append(line + ' ')
            line = word
        else:
            line = candidate
        if line.endswith('\n'):
            chunks.append(line)
            line = ''
    if line:
        chunks.append(line)

    body = ('\n' + indent + '  ').join(dart_string(c) for c in chunks)

    # Argüman listesi de uzunsa her ifade kendi satırına.
    if column + len(args) > 70 and len(exprs) > 1:
        sep = ',\n' + indent + '    '
        arglist = '[\n%s    %s,\n%s  ]' % (indent, sep.join(exprs), indent)
    else:
        arglist = '[%s]' % args

    return 'tf(\n%s  %s,\n%s  %s,\n%s)' % (
        indent, body, indent, arglist, indent,
    )


def process(path: str, apply: bool):
    if path in SKIP_FILES:
        return []
    src = io.open(path, encoding='utf-8').read()
    lits = merge_adjacent(strip_and_scan(src), src)

    edits = []
    for start, end, value, raw, interp in lits:
        if raw or not interp:
            continue
        ctx = context_before(src, start)
        if not looks_user_facing(value, ctx):
            continue
        # Zaten şablon hâlindeyse (tf çağrısı içinde) dokunma.
        if re.search(r'\btf\s*\(\s*$', ctx):
            continue
        parsed = parse_interpolated(src[start:end])
        if parsed is None:
            continue
        template, exprs = parsed
        if not exprs or not worth_translating(template):
            continue
        column = start - (src.rfind('\n', 0, start) + 1)
        replacement = render_call(template, exprs, column)
        edits.append((start, end, replacement, template))

    if apply and edits:
        out = src
        for start, end, replacement, _ in reversed(edits):
            out = out[:start] + replacement + out[end:]
        io.open(path, 'w', encoding='utf-8').write(out)
    return edits


def main():
    apply = '--apply' in sys.argv
    verbose = '--verbose' in sys.argv
    total = 0
    files = 0
    for root, _dirs, names in os.walk(LIB):
        for f in sorted(names):
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            path = os.path.join(root, f)
            edits = process(path, apply)
            if edits:
                files += 1
                total += len(edits)
                print('%-58s %d' % (path, len(edits)))
                if verbose:
                    for _s, _e, _r, tpl in edits:
                        print('      %s' % tpl.replace('\n', '\\n')[:88])
    print('%d dosyada %d şablon%s' % (
        files, total, ' uygulandı' if apply else ' bulundu'))


if __name__ == '__main__':
    sys.exit(main())
