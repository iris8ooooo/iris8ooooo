import 'package:flutter/material.dart';

/// 앱 전역 테마. 주 사용층(40~60대)을 위해 기본 글씨를 표준보다 크게,
/// 대비를 높게 잡는다. 큰글씨 단계 조절은 M6에서 설정으로 확장한다.
ThemeData buildAppTheme(Brightness brightness, {int seedArgb = 0xFF1565C0}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(seedArgb),
    brightness: brightness,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.comfortable,
  );
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 17),
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      titleTextStyle: TextStyle(fontSize: 18, color: scheme.onSurface),
    ),
  );
}
