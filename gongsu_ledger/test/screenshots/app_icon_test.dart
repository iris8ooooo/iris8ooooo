// 앱 아이콘 생성기 — 디자인 도구 없이 코드로 1024px 아이콘을 그린다.
//
//   flutter test test/screenshots/app_icon_test.dart --dart-define=ICON_OUT=1
//   dart run flutter_launcher_icons        # 플랫폼별 크기 생성 (pubspec 설정)
//
// ICON_OUT 이 없으면 건너뛰므로 일반 `flutter test` 에 영향이 없다.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const bool iconOut = String.fromEnvironment('ICON_OUT') != '';
const double _size = 1024;
const Color _blue = Color(0xFF1565C0);
const Color _deepBlue = Color(0xFF0D47A1);

void main() {
  setUpAll(() async {
    if (!iconOut) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('NanumGothic')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/NanumGothic-Bold.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  });

  /// 달력 카드 + "공수" 글자. [scale] 로 안전 영역(안드로이드 적응형 66%)에 맞춘다.
  void drawCard(Canvas canvas, {required double scale}) {
    canvas.save();
    canvas.translate(_size / 2, _size / 2);
    canvas.scale(scale);
    canvas.translate(-_size / 2, -_size / 2);

    const card = Rect.fromLTWH(172, 192, 680, 640);
    final cardR = RRect.fromRectAndRadius(card, const Radius.circular(88));
    canvas.drawRRect(cardR, Paint()..color = Colors.white);

    // 상단 바 (달력 머리)
    canvas.save();
    canvas.clipRRect(cardR);
    canvas.drawRect(
      const Rect.fromLTWH(172, 192, 680, 150),
      Paint()..color = _deepBlue,
    );
    canvas.restore();
    // 고리 두 개
    for (final x in [352.0, 672.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 192), width: 44, height: 120),
          const Radius.circular(22),
        ),
        Paint()..color = Colors.white,
      );
    }

    // "공수" 글자
    final painter = TextPainter(
      text: const TextSpan(
        text: '공수',
        style: TextStyle(
          fontFamily: 'NanumGothic',
          fontWeight: FontWeight.w700,
          fontSize: 250,
          color: _blue,
          letterSpacing: -4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((_size - painter.width) / 2, 372));

    // 기록 점 세 개 (달력 마커)
    const dots = [Color(0xFFEF6C00), Color(0xFF2E7D32), Color(0xFFC2185B)];
    for (var i = 0; i < dots.length; i++) {
      canvas.drawCircle(
        Offset(_size / 2 + (i - 1) * 110, 730),
        30,
        Paint()..color = dots[i],
      );
    }
    canvas.restore();
  }

  Future<void> savePng(
    String path, {
    required bool background,
    required double scale,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (background) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _size, _size),
        Paint()..color = _blue,
      );
    }
    drawCard(canvas, scale: scale);
    final image = await recorder.endRecording().toImage(
      _size.toInt(),
      _size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('앱 아이콘 PNG 생성', (tester) async {
    await tester.runAsync(() async {
      Directory('assets/icon').createSync(recursive: true);
      // iOS·일반: 파란 배경 + 카드
      await savePng('assets/icon/app_icon.png', background: true, scale: 1.0);
      // Android 적응형 전경: 투명 배경, 안전 영역(중앙 66%) 안에 카드
      await savePng(
        'assets/icon/app_icon_foreground.png',
        background: false,
        scale: 0.86,
      );
    });
  }, skip: !iconOut);
}
