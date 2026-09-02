/// 화면 설정(큰글씨·화면 모드·주 시작 요일·테마 색). 순수 값 객체.
///
/// 저장 형식은 전부 문자열(prefs 미러 + AppSettings 동일 키). 배율은 double 금지
/// 규칙에 따라 백분율 정수로 둔다 — UI 에서만 /100 한다.
library;

enum TextSize {
  normal(100, '보통'),
  large(115, '크게'),
  xlarge(130, '아주 크게');

  const TextSize(this.scalePercent, this.label);

  final int scalePercent;
  final String label;

  static TextSize parse(String? raw) =>
      values.firstWhere((v) => v.name == raw, orElse: () => normal);
}

enum ScreenMode {
  system('시스템 따라가기'),
  light('밝게'),
  dark('어둡게');

  const ScreenMode(this.label);

  final String label;

  static ScreenMode parse(String? raw) =>
      values.firstWhere((v) => v.name == raw, orElse: () => system);
}

enum WeekStart {
  sunday(DateTime.sunday, '일요일'),
  monday(DateTime.monday, '월요일');

  const WeekStart(this.weekday, this.label);

  /// DateTime.weekday 규약 (월=1 … 일=7)
  final int weekday;
  final String label;

  static WeekStart parse(String? raw) =>
      values.firstWhere((v) => v.name == raw, orElse: () => sunday);
}

/// 테마 색 후보. id 0(파랑)은 무료, 나머지는 프로.
class ThemeColorOption {
  const ThemeColorOption(this.id, this.label, this.argb);

  final int id;
  final String label;
  final int argb;
}

const List<ThemeColorOption> themeColorOptions = [
  ThemeColorOption(0, '파랑', 0xFF1565C0),
  ThemeColorOption(1, '초록', 0xFF2E7D32),
  ThemeColorOption(2, '주황', 0xFFE65100),
  ThemeColorOption(3, '보라', 0xFF6A1B9A),
  ThemeColorOption(4, '청록', 0xFF00695C),
];

ThemeColorOption themeColorById(int id) => themeColorOptions.firstWhere(
  (o) => o.id == id,
  orElse: () => themeColorOptions.first,
);

class AppearanceKeys {
  AppearanceKeys._();

  static const String textSize = 'text_size';
  static const String screenMode = 'screen_mode';
  static const String weekStart = 'week_start';
  static const String themeColor = 'theme_color';
}

class Appearance {
  const Appearance({
    this.textSize = TextSize.normal,
    this.screenMode = ScreenMode.system,
    this.weekStart = WeekStart.sunday,
    this.themeColorId = 0,
  });

  final TextSize textSize;
  final ScreenMode screenMode;
  final WeekStart weekStart;
  final int themeColorId;

  Appearance copyWith({
    TextSize? textSize,
    ScreenMode? screenMode,
    WeekStart? weekStart,
    int? themeColorId,
  }) => Appearance(
    textSize: textSize ?? this.textSize,
    screenMode: screenMode ?? this.screenMode,
    weekStart: weekStart ?? this.weekStart,
    themeColorId: themeColorId ?? this.themeColorId,
  );

  /// 저장소 문자열 → 설정. 모르는 값은 기본값으로 (앱 다운그레이드 대비).
  static Appearance fromStrings(String? Function(String key) read) =>
      Appearance(
        textSize: TextSize.parse(read(AppearanceKeys.textSize)),
        screenMode: ScreenMode.parse(read(AppearanceKeys.screenMode)),
        weekStart: WeekStart.parse(read(AppearanceKeys.weekStart)),
        themeColorId: int.tryParse(read(AppearanceKeys.themeColor) ?? '') ?? 0,
      );
}
