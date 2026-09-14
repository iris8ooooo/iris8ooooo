import 'package:flutter/material.dart';

/// 확정 디자인 "잉크 달력"(2026-09-14 오너 결정)의 색·글꼴 토큰.
///
/// 종이 위에 잉크 한 가지. 공수는 잉크의 **농도**(4단계)로, 오늘은 금색,
/// 쉬는 날은 빨강, 토요일은 파랑. 장식색은 없다 — 색은 뜻이 있을 때만.
/// 다크모드는 같은 토큰을 어두운 값으로 바꾼 것이다.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.onAccent,
    required this.red,
    required this.blue,
    required this.gold,
    required this.tint05,
    required this.tint10,
    required this.tint15,
    required this.tint20,
    required this.onTintDark,
  });

  /// 바탕(종이)
  final Color paper;

  /// 카드·시트 면
  final Color surface;

  /// 본문 글자
  final Color text;

  /// 보조 글자
  final Color muted;

  /// 옅은 선
  final Color line;

  /// 진한 선(외곽선 버튼)
  final Color lineStrong;

  /// 잉크(브랜드) — 채운 버튼·켜진 탭·강조 숫자
  final Color accent;

  /// 잉크 위 글자
  final Color onAccent;

  /// 공휴일·일요일·공제
  final Color red;

  /// 토요일
  final Color blue;

  /// 오늘
  final Color gold;

  /// 공수 농도 0.5 이하
  final Color tint05;

  /// 공수 농도 1 이하
  final Color tint10;

  /// 공수 농도 1.5 이하
  final Color tint15;

  /// 공수 농도 1.5 초과
  final Color tint20;

  /// 가장 진한 농도 위 글자
  final Color onTintDark;

  /// centi-공수(1공수 = 100)에 따른 칸 배경.
  Color tintForCenti(int centi) => centi <= 50
      ? tint05
      : centi <= 100
      ? tint10
      : centi <= 150
      ? tint15
      : tint20;

  /// 가장 진한 농도인가 (글자를 밝게 써야 하는 칸).
  bool isDarkTint(int centi) => centi > 150;

  /// 밝은 테마. [ink]가 기본 남색이면 확정 시안의 값 그대로, 다른 색(프로
  /// 테마)이면 종이와 잉크 사이를 보간해 농도를 만든다.
  static AppColors light(Color ink) {
    const paper = Color(0xFFFBFAF7);
    final isDefault = ink.toARGB32() == kDefaultInkArgb;
    return AppColors(
      paper: paper,
      surface: const Color(0xFFFFFFFF),
      text: isDefault ? ink : const Color(0xFF1B2A4A),
      muted: const Color(0xFF6F7787),
      line: const Color(0xFFE4E1DA),
      lineStrong: const Color(0xFFC6C2B8),
      accent: ink,
      onAccent: const Color(0xFFFFFFFF),
      red: const Color(0xFFC0392B),
      blue: const Color(0xFF4A6FA5),
      gold: const Color(0xFFC9A227),
      tint05: isDefault
          ? const Color(0xFFE6EAF2)
          : Color.lerp(paper, ink, 0.12)!,
      tint10: isDefault
          ? const Color(0xFFC5CFE1)
          : Color.lerp(paper, ink, 0.30)!,
      tint15: isDefault
          ? const Color(0xFF94A6C8)
          : Color.lerp(paper, ink, 0.55)!,
      tint20: isDefault
          ? const Color(0xFF55699A)
          : Color.lerp(paper, ink, 0.82)!,
      onTintDark: const Color(0xFFFFFFFF),
    );
  }

  /// 어두운 테마. 잉크는 어두운 바탕 위에서 읽히도록 밝힌다.
  static AppColors dark(Color ink) {
    const paper = Color(0xFF12161F);
    const surface = Color(0xFF1A2030);
    final accent = Color.lerp(ink, Colors.white, 0.45)!;
    return AppColors(
      paper: paper,
      surface: surface,
      text: const Color(0xFFEEF1F6),
      muted: const Color(0xFF9AA3B5),
      line: const Color(0xFF2A3242),
      lineStrong: const Color(0xFF3B4456),
      accent: accent,
      onAccent: paper,
      red: const Color(0xFFE4655C),
      blue: const Color(0xFF7FA0D6),
      gold: const Color(0xFFD9B449),
      tint05: Color.lerp(surface, accent, 0.22)!,
      tint10: Color.lerp(surface, accent, 0.40)!,
      tint15: Color.lerp(surface, accent, 0.62)!,
      tint20: Color.lerp(surface, accent, 0.92)!,
      onTintDark: paper,
    );
  }

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? text,
    Color? muted,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? onAccent,
    Color? red,
    Color? blue,
    Color? gold,
    Color? tint05,
    Color? tint10,
    Color? tint15,
    Color? tint20,
    Color? onTintDark,
  }) => AppColors(
    paper: paper ?? this.paper,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    red: red ?? this.red,
    blue: blue ?? this.blue,
    gold: gold ?? this.gold,
    tint05: tint05 ?? this.tint05,
    tint10: tint10 ?? this.tint10,
    tint15: tint15 ?? this.tint15,
    tint20: tint20 ?? this.tint20,
    onTintDark: onTintDark ?? this.onTintDark,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      paper: l(paper, other.paper),
      surface: l(surface, other.surface),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      red: l(red, other.red),
      blue: l(blue, other.blue),
      gold: l(gold, other.gold),
      tint05: l(tint05, other.tint05),
      tint10: l(tint10, other.tint10),
      tint15: l(tint15, other.tint15),
      tint20: l(tint20, other.tint20),
      onTintDark: l(onTintDark, other.onTintDark),
    );
  }
}

/// 기본 잉크(남색). 테마 색 id 0.
const int kDefaultInkArgb = 0xFF1B2A4A;

extension AppColorsContext on BuildContext {
  /// 현재 테마의 잉크 달력 토큰.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// 글꼴. 본문·숫자는 Pretendard(4굵기 내장), 월 이름·화면 제목만 명조
/// (Song Myung, 제목 글자만 잘라 내장 — 없는 글자는 Pretendard 로 떨어진다).
abstract final class AppFonts {
  static const String body = 'Pretendard';
  static const String display = 'SongMyung';

  /// 화면 제목("9월", "정산")용 명조 스타일.
  static TextStyle displayStyle({double size = 34, Color? color}) => TextStyle(
    fontFamily: display,
    fontFamilyFallback: const [body],
    fontSize: size,
    height: 1.0,
    fontWeight: FontWeight.w400,
    color: color,
  );
}

/// 앱 전역 테마. 주 사용층(40~60대)을 위해 글씨는 표준보다 크게, 대비는 높게.
/// [seedArgb]는 잉크 색(테마 색 설정, 프로) — 기본은 남색.
ThemeData buildAppTheme(
  Brightness brightness, {
  int seedArgb = kDefaultInkArgb,
}) {
  final ink = Color(seedArgb);
  final c = brightness == Brightness.light
      ? AppColors.light(ink)
      : AppColors.dark(ink);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.tint05,
    onPrimaryContainer: c.text,
    secondary: c.gold,
    onSecondary: brightness == Brightness.light ? Colors.white : c.paper,
    secondaryContainer: c.tint05,
    onSecondaryContainer: c.text,
    tertiary: c.blue,
    onTertiary: Colors.white,
    tertiaryContainer: c.tint05,
    onTertiaryContainer: c.text,
    error: c.red,
    onError: Colors.white,
    errorContainer: brightness == Brightness.light
        ? const Color(0xFFF8E3E0)
        : const Color(0xFF4A2320),
    onErrorContainer: c.red,
    surface: c.paper,
    onSurface: c.text,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.tint05,
    surfaceContainerHighest: c.tint05,
    outline: c.lineStrong,
    outlineVariant: c.line,
    inverseSurface: c.text,
    onInverseSurface: c.paper,
    inversePrimary: c.tint10,
    shadow: Colors.black,
    scrim: Colors.black,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: AppFonts.body,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: c.paper,
    extensions: [c],
  );
  final stadium = const StadiumBorder();
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: c.paper,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: c.text,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: c.text, size: 22),
    ),
    iconTheme: IconThemeData(color: c.text, size: 22),
    cardTheme: base.cardTheme.copyWith(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.line.withValues(alpha: 0.7)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(64, 52),
        shape: stadium,
        textStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.lineStrong, width: 1.5),
        minimumSize: const Size(64, 52),
        shape: stadium,
        textStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(64, 48),
        shape: stadium,
        textStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: 2,
      shape: stadium,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: c.tint05,
      selectedColor: c.accent,
      disabledColor: c.line,
      side: BorderSide.none,
      shape: stadium,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      // Chip 은 labelStyle 을 상태 해석 없이 merge 만 하므로 WidgetStateTextStyle
      // 을 주면 글자가 □ 로 깨진다. 평범한 TextStyle 두 벌(기본/선택)로 둔다.
      labelStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: c.text,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: c.onAccent,
      ),
      iconTheme: IconThemeData(color: c.text, size: 18),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        color: c.muted,
      ),
      iconColor: c.text,
      minVerticalPadding: 10,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: c.line,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: c.text,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 16,
        color: c.text,
        height: 1.5,
      ),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.tint05,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      labelStyle: TextStyle(color: c.muted),
      hintStyle: TextStyle(color: c.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 15,
        color: c.paper,
      ),
      actionTextColor: c.gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
  );
}
