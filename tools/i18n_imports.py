#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`Text(` kullanan her dosyayı çeviren Text'e bağlar.

Çalıştırma:
    python3 tools/i18n_imports.py            # ne yapacağını yazar
    python3 tools/i18n_imports.py --apply    # uygular

Yaptığı iki şey:
  1. `import 'package:material_ui/material_ui.dart';` satırına
     `hide Text` ekler (varsa mevcut `hide` listesine katar).
  2. `core/i18n/text.dart` içe aktarmasını ekler.

Neden gerekli: çeviri, Material'ın Text'ini gizleyip yerine kendi
Text'imizi koymaya dayanıyor (bkz. lib/core/i18n/text.dart). Bir dosya
bu ikisini yapmazsa oradaki metinler sessizce Türkçe kalır.
`test/i18n_test.dart` bunu ayrıca denetler.
"""

from __future__ import annotations

import io
import os
import re
import sys

LIB = 'lib'
SKIP_DIRS = (os.path.join('lib', 'core', 'i18n'),)
TEXT_CALL = re.compile(r'(?<![A-Za-z0-9_.$])Text\s*\(')
MATERIAL = re.compile(
    r"^import 'package:material_ui/material_ui\.dart'([^;]*);$", re.M
)
IMPORT_LINE = re.compile(r"^import .*;$", re.M)


def relative_to_i18n(path: str) -> str:
    """Dosyadan lib/core/i18n/text.dart'a göreli yol."""
    rel = os.path.relpath(
        os.path.join(LIB, 'core', 'i18n', 'text.dart'), os.path.dirname(path)
    )
    return rel.replace(os.sep, '/')


def add_hide(suffix: str) -> str:
    """material_ui içe aktarmasına `hide Text` ekler."""
    suffix = suffix.strip()
    if not suffix:
        return ' hide Text'
    hide = re.search(r'\bhide\s+([A-Za-z0-9_,\s]+)$', suffix)
    if hide:
        names = [n.strip() for n in hide.group(1).split(',') if n.strip()]
        if 'Text' in names:
            return ' ' + suffix
        names.append('Text')
        names.sort()
        return ' ' + suffix[: hide.start()].strip() + ' hide ' + ', '.join(names)
    # `show ...` varsa gizlemeye gerek yok ama Text gösteriliyorsa çıkar.
    show = re.search(r'\bshow\s+([A-Za-z0-9_,\s]+)$', suffix)
    if show:
        names = [n.strip() for n in show.group(1).split(',') if n.strip()]
        names = [n for n in names if n != 'Text']
        return ' ' + suffix[: show.start()].strip() + ' show ' + ', '.join(names)
    return ' ' + suffix + ' hide Text'


TF_CALL = re.compile(r'(?<![A-Za-z0-9_.$])tf\s*\(')


def add_import(out: str, want: str):
    """İçe aktarmayı son import satırının ardına ekler.

    Hiç import yoksa (saf Dart çözümleyiciler böyle) baştaki belge
    yorumundan ve `library;` satırından SONRAYA konur — yoksa dosyanın
    açıklaması bölünür.
    """
    if want in out:
        return out, False
    imports = list(IMPORT_LINE.finditer(out))
    if imports:
        last = imports[-1]
        return out[: last.end()] + '\n' + want + out[last.end():], True

    lines = out.split('\n')
    i = 0
    while i < len(lines) and (
        lines[i].startswith('///')
        or lines[i].startswith('//')
        or not lines[i].strip()
        or lines[i].strip() == 'library;'
    ):
        i += 1
    lines.insert(i, want)
    lines.insert(i + 1, '')
    return '\n'.join(lines), True


def without_comments(src: str) -> str:
    """Yorumları siler.

    Bu dosyaların çoğunda çeviri düzeneği YORUMLA anlatılıyor; yorumdaki
    `Text(` yüzünden gereksiz içe aktarma eklenmemeli.
    """
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    return re.sub(r'//[^\n]*', '', src)


def process(path: str, apply: bool):
    src = io.open(path, encoding='utf-8').read()
    code = without_comments(src)
    needs_text = bool(TEXT_CALL.search(code))
    needs_tf = bool(TF_CALL.search(code))
    if not needs_text and not needs_tf:
        return None

    changed = []
    out = src

    if needs_tf:
        rel = os.path.relpath(
            os.path.join(LIB, 'core', 'i18n', 'i18n.dart'),
            os.path.dirname(path),
        ).replace(os.sep, '/')
        out, added = add_import(out, "import '%s';" % rel)
        if added:
            changed.append('i18n.dart eklendi')

    if not needs_text:
        if changed and apply and out != src:
            io.open(path, 'w', encoding='utf-8').write(out)
        return (path, changed) if changed else None

    m = MATERIAL.search(out)
    if m and 'hide Text' not in m.group(0) and ' show ' not in m.group(0):
        out = (
            out[: m.start()]
            + "import 'package:material_ui/material_ui.dart'%s;" % add_hide(m.group(1))
            + out[m.end():]
        )
        changed.append('hide Text')
    elif not m:
        changed.append('UYARI: material_ui içe aktarması yok')

    rel = relative_to_i18n(path)
    want = "import '%s';" % rel
    if want not in out:
        imports = list(IMPORT_LINE.finditer(out))
        if not imports:
            return (path, ['UYARI: hiç import yok'])
        last = imports[-1]
        out = out[: last.end()] + '\n' + want + out[last.end():]
        changed.append('text.dart eklendi')

    if changed and apply and out != src:
        io.open(path, 'w', encoding='utf-8').write(out)
    return (path, changed) if changed else None


def main():
    apply = '--apply' in sys.argv
    touched = 0
    for root, _dirs, files in os.walk(LIB):
        if root.startswith(SKIP_DIRS):
            continue
        for f in sorted(files):
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            res = process(os.path.join(root, f), apply)
            if res:
                touched += 1
                print('%-62s %s' % (res[0], ', '.join(res[1])))
    print('%d dosya%s' % (touched, ' güncellendi' if apply else ' güncellenecek'))


if __name__ == '__main__':
    sys.exit(main())
