#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""t() sarılan ifadeyi kapsayan `const` sözcüğünü kaldırır.

Çalıştırma:
    python3 tools/i18n_drop_const.py            # ne yapacağını yazar
    python3 tools/i18n_drop_const.py --apply    # uygular

Neden gerekli: `const InputDecoration(labelText: 'Not')` sabit bir
ifadedir; içine t() koyunca Dart "sabit ifadede yöntem çağrılamaz"
diyor. Çeviri çalışma zamanında olduğu için o ifade artık sabit
olamaz — `const`u atıyoruz. Dışarıdaki `const` listeler etkilenmiyor,
yalnız t()'yi KAPSAYAN en yakın const kaldırılıyor.
"""

from __future__ import annotations

import io
import os
import re
import sys

LIB = 'lib'
SKIP_DIR = os.path.join('core', 'i18n')
CALL = re.compile(r"(?<![\w])t\(")


def enclosing_const(src: str, pos: int):
    """t( çağrısını kapsayan en yakın `const` sözcüğünün yerini bulur."""
    depth = 0
    i = pos
    while i > 0:
        c = src[i]
        if c == ')':
            depth += 1
        elif c == '(':
            if depth == 0:
                # Bu parantezi açan yapıcının adını geri doğru oku.
                j = i - 1
                while j > 0 and (src[j].isalnum() or src[j] in '_.<> \n'):
                    j -= 1
                head = src[j + 1:i]
                m = re.search(r'(?<![\w])const\s+$', src[:j + 1 + len(head) -
                                                        len(head.lstrip())])
                if m is None:
                    m = re.search(r'(?<![\w])const\s+(?=[\w<])',
                                  src[max(0, j - 40):i])
                    if m:
                        start = max(0, j - 40) + m.start()
                        end = max(0, j - 40) + m.end()
                        between = src[end:i]
                        if re.fullmatch(r'[\w.<>, \n]*', between):
                            return start, end
                    return None
                return m.start(), m.end()
            depth -= 1
        i -= 1
    return None


def process(path: str, apply: bool) -> int:
    src = io.open(path, encoding='utf-8').read()
    cuts = set()
    for m in CALL.finditer(src):
        found = enclosing_const(src, m.start())
        if found:
            cuts.add(found)
    if not cuts:
        return 0
    out = src
    for start, end in sorted(cuts, reverse=True):
        out = out[:start] + out[end:]
    if apply:
        io.open(path, 'w', encoding='utf-8').write(out)
    return len(cuts)


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
    print('%d dosyada %d const%s' %
          (files, total, ' kaldırıldı' if apply else ' kaldırılacak'))


if __name__ == '__main__':
    sys.exit(main())
