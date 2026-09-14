// 앱 아이콘 생성기 — 디자인 도구 없이 코드로 1024px 아이콘을 그린다.
// 확정 시안 "잉크 격자"(5번): 종이 바탕, 잉크 막대 하나, 칸 12개(0.5·1·1.5·2+
// 농도), 금색 한 칸이 오늘.
//
//   flutter test test/screenshots/app_icon_test.dart --dart-define=ICON_OUT=1
//   dart run flutter_launcher_icons        # 플랫폼별 크기 생성 (pubspec 설정)
//
// ICON_OUT 이 없으면 건너뛰므로 일반 `flutter test` 에 영향이 없다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const bool iconOut = String.fromEnvironment('ICON_OUT') != '';
const double _size = 1024;

// 시안 토큰 (lib/ui/app_theme.dart 의 기본 잉크 팔레트와 같은 값).
const Color _paper = Color(0xFFFBFAF7);
const Color _ink = Color(0xFF1B2A4A);
const Color _gold = Color(0xFFC9A227);
const List<Color> _cells = [
  Color(0xFFE6EAF2), Color(0xFFC5CFE1), Color(0xFF94A6C8), Color(0xFF55699A), //
  Color(0xFFC5CFE1), Color(0xFF55699A), _gold, Color(0xFF94A6C8), //
  Color(0xFF94A6C8), Color(0xFFE6EAF2), Color(0xFF55699A), Color(0xFFC5CFE1), //
];

void main() {
  /// 256 단위 시안 좌표계로 그린다. [scale] 로 안드로이드 적응형 안전 영역에 맞춘다.
  void drawGrid(Canvas canvas, {required double scale}) {
    const u = _size / 256;
    canvas.save();
    canvas.translate(_size / 2, _size / 2);
    canvas.scale(scale);
    canvas.translate(-_size / 2, -_size / 2);
    canvas.scale(u);

    // 잉크 막대
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 36, 176, 10),
        const Radius.circular(5),
      ),
      Paint()..color = _ink,
    );
    // 칸 4×3
    for (var i = 0; i < _cells.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(40 + (i % 4) * 46, 62 + (i ~/ 4) * 46, 38, 38),
          const Radius.circular(9),
        ),
        Paint()..color = _cells[i],
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
        Paint()..color = _paper,
      );
    }
    drawGrid(canvas, scale: scale);
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
      // iOS·일반: 종이 바탕 + 격자 (모서리는 OS 가 깎는다)
      await savePng('assets/icon/app_icon.png', background: true, scale: 1.0);
      // Android 적응형 전경: 투명 배경. 원형 마스크의 안전 영역(지름 66/108)
      // 안에 격자 모서리까지 들어오도록 0.64 배 — 배경색은 pubspec 의
      // adaptive_icon_background(종이색).
      await savePng(
        'assets/icon/app_icon_foreground.png',
        background: false,
        scale: 0.64,
      );
    });
  }, skip: !iconOut);
}
