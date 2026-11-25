// Uygulama ikonlarını amblemin TEK kaynağından üretir.
//
// Çalıştırma:  flutter test tools/gen_icons.dart
//
// Android launcher (adaptive + legacy), iOS AppIcon, bildirim ikonu ve
// açılış ekranı görseli hep lib/core/brand/brand_mark.dart içindeki
// BrandMarkPainter ile çizilir. Böylece hiçbir yerde farklı bir logo
// oluşamaz: ikon dosyaları uygulamanın kendi boyayıcısının çıktısıdır.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bobrek_dostu/core/brand/brand_mark.dart';
import 'package:bobrek_dostu/core/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _android = 'android/app/src/main/res';
const _ios = 'ios/Runner/Assets.xcassets';
const _preview = 'build/brand';

Future<Uint8List> _render({
  required double canvas,
  required double markFraction,
  Color? background,
  bool vignette = false,
  Color? monochrome,
  AppPalette palette = AppPalette.warmLight,
  BrandDetail detail = BrandDetail.full,
  bool shadow = true,
}) async {
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, canvas, canvas);

  if (background != null) {
    c.drawRect(rect, Paint()..color = background);
    if (vignette) {
      // Uygulamanın sıcak zemininin aynısı: merkezde biraz daha açık.
      c.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.35),
            radius: 1.1,
            colors: [
              const Color(0x8CFFFFFF),
              const Color(0x00FFFFFF),
            ],
          ).createShader(rect),
      );
      c.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.55, 0.75),
            radius: 1.0,
            colors: [
              palette.backgroundDeep.withValues(alpha: 0.55),
              palette.backgroundDeep.withValues(alpha: 0.0),
            ],
          ).createShader(rect),
      );
    }
  }

  final markSize = canvas * markFraction;
  final offset = (canvas - markSize) / 2;
  c.save();
  c.translate(offset, offset);
  BrandMarkPainter(
    palette: palette,
    detail: detail,
    monochrome: monochrome,
    withShadow: shadow,
  ).paint(c, Size.square(markSize));
  c.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvas.round(), canvas.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}

void _writeText(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content.trimLeft());
  stdout.writeln('       json  $path');
}

void _write(String path, Uint8List bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  stdout.writeln('  ${bytes.lengthInBytes ~/ 1024} KB  $path');
}

void main() {
  test('amblemden ikonları üret', () async {
    stdout.writeln('Amblem -> ikon üretimi');

    // ---------- önizleme (tasarım kontrolü) ----------
    _write('$_preview/preview-1024-light.png',
        await _render(canvas: 1024, markFraction: 0.64,
            background: AppPalette.warmLight.background, vignette: true));
    _write('$_preview/preview-1024-dark.png',
        await _render(canvas: 1024, markFraction: 0.64,
            background: AppPalette.warmDark.background, vignette: true,
            palette: AppPalette.warmDark));
    for (final s in [24.0, 48.0, 96.0, 192.0]) {
      _write('$_preview/preview-$s.png',
          await _render(canvas: s, markFraction: 0.88,
              background: AppPalette.warmLight.background,
              detail: BrandMark.detailFor(s * 0.88)));
    }

    // ---------- iOS AppIcon ----------
    // Tek 1024 görsel + açık/karanlık/tinted varyantlar. Xcode 14'ten beri
    // tek boyut yeterli; sistem gerisini kendi ölçekler.
    _writeText('$_ios/AppIcon.appiconset/Contents.json', '''
{
  "images" : [
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "dark" }
      ],
      "filename" : "Icon-App-Dark-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        { "appearance" : "luminosity", "value" : "tinted" }
      ],
      "filename" : "Icon-App-Tinted-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''');

    _write('$_ios/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
        await _render(canvas: 1024, markFraction: 0.64,
            background: AppPalette.warmLight.background, vignette: true));
    // iOS 18+ karanlık ve şeffaf (tinted) varyantları
    _write('$_ios/AppIcon.appiconset/Icon-App-Dark-1024.png',
        await _render(canvas: 1024, markFraction: 0.64,
            background: AppPalette.warmDark.background, vignette: true,
            palette: AppPalette.warmDark));
    _write('$_ios/AppIcon.appiconset/Icon-App-Tinted-1024.png',
        await _render(canvas: 1024, markFraction: 0.64,
            background: const Color(0xFF000000),
            monochrome: const Color(0xFFFFFFFF)));

    // iOS açılış ekranı görseli
    for (final e in {'': 1.0, '@2x': 2.0, '@3x': 3.0}.entries) {
      _write('$_ios/LaunchImage.imageset/LaunchImage${e.key}.png',
          await _render(canvas: 160 * e.value, markFraction: 1.0,
              detail: BrandDetail.full));
    }

    // ---------- Android adaptive ----------
    // Güvenli alan 108dp kutunun ortadaki 66dp'si; 432px tuvalde ~0.52.
    _write('$_android/mipmap-xxxhdpi/ic_launcher_foreground.png',
        await _render(canvas: 432, markFraction: 0.52));
    _write('$_android/mipmap-xxhdpi/ic_launcher_foreground.png',
        await _render(canvas: 324, markFraction: 0.52));
    _write('$_android/mipmap-xhdpi/ic_launcher_foreground.png',
        await _render(canvas: 216, markFraction: 0.52));
    _write('$_android/mipmap-hdpi/ic_launcher_foreground.png',
        await _render(canvas: 162, markFraction: 0.52));
    _write('$_android/mipmap-mdpi/ic_launcher_foreground.png',
        await _render(canvas: 108, markFraction: 0.52,
            detail: BrandDetail.compact, shadow: false));

    // Material You "themed icon" katmanı: tek renk siluet.
    _write('$_android/drawable-xxxhdpi/ic_launcher_monochrome.png',
        await _render(canvas: 432, markFraction: 0.52,
            monochrome: const Color(0xFF000000)));

    // ---------- Android legacy (yuvarlak/kare) ----------
    const legacy = {
      'mdpi': 48.0,
      'hdpi': 72.0,
      'xhdpi': 96.0,
      'xxhdpi': 144.0,
      'xxxhdpi': 192.0,
    };
    for (final e in legacy.entries) {
      final bytes = await _render(
        canvas: e.value,
        markFraction: 0.74,
        background: AppPalette.warmLight.background,
        vignette: e.value >= 96,
        detail: BrandMark.detailFor(e.value * 0.74),
        shadow: e.value >= 96,
      );
      _write('$_android/mipmap-${e.key}/ic_launcher.png', bytes);
      _write('$_android/mipmap-${e.key}/ic_launcher_round.png', bytes);
    }

    // ---------- bildirim ikonu (beyaz, şeffaf zemin) ----------
    const notif = {
      'mdpi': 24.0,
      'hdpi': 36.0,
      'xhdpi': 48.0,
      'xxhdpi': 72.0,
      'xxxhdpi': 96.0,
    };
    for (final e in notif.entries) {
      _write(
        '$_android/drawable-${e.key}/ic_notification.png',
        await _render(
          canvas: e.value,
          markFraction: 0.92,
          monochrome: const Color(0xFFFFFFFF),
          detail: e.value < 36 ? BrandDetail.minimal : BrandDetail.compact,
        ),
      );
    }

    stdout.writeln('Bitti.');
  });
}
