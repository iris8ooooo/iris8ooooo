import 'dart:convert';

import '../db/app_database.dart';

/// key-value 설정 저장소. 값은 문자열(JSON) — 스키마 변경 없이 확장.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// 입력 시트에서 마지막으로 고른 업체 — 다음 입력의 기본값.
  static const String keyLastSiteId = 'last_site_id';

  /// 공수 확인서(PDF)에 찍는 근로자 이름.
  static const String keyReportWorkerName = 'report_worker_name';

  /// 세금 끝전 처리 방식 (TaxRounding.code). 기본 10원 미만 절사.
  static const String keyTaxRounding = 'tax_rounding';

  /// 정산 마감 주기 시작일 (1~28). 예: 21 → 전월 21일 ~ 당월 20일.
  static const String keySettleCycleStartDay = 'settle_cycle_start_day';

  /// M6 — prefs 미러와 같은 키를 쓴다 (`domain/appearance.dart` AppearanceKeys 참조).
  static const String keyTextSize = 'text_size';
  static const String keyScreenMode = 'screen_mode';
  static const String keyWeekStart = 'week_start';
  static const String keyThemeColor = 'theme_color';

  /// '1' 이면 프로(일회성 구매) 잠금 해제.
  static const String keyProUnlocked = 'pro_unlocked';

  /// '1' 이면 온보딩(직군 선택) 완료.
  static const String keyOnboardingDone = 'onboarding_done';

  /// 온보딩에서 고른 직군 ('construction' | 'shipyard' | 'custom').
  static const String keyJobKind = 'job_kind';

  /// 연도별 세율 오버라이드 JSON. 값이 비어 있으면 기본 테이블 사용.
  static String keyTaxRatesOverride(int year) => 'tax_rates_override_$year';

  /// 연도별 사용자 세율 오버라이드 (없으면 null).
  Stream<Map<String, Object?>?> watchTaxRatesOverride(int year) =>
      watch(keyTaxRatesOverride(year)).map(_decodeJsonObject);

  Future<Map<String, Object?>?> getTaxRatesOverride(int year) async =>
      _decodeJsonObject(await get(keyTaxRatesOverride(year)));

  Future<void> setTaxRatesOverride(int year, Map<String, int> values) =>
      set(keyTaxRatesOverride(year), jsonEncode(values));

  /// 기본 테이블로 되돌리기 (빈 값 저장 — 행 삭제 없이 "없음"을 표현).
  Future<void> clearTaxRatesOverride(int year) =>
      set(keyTaxRatesOverride(year), '');

  static Map<String, Object?>? _decodeJsonObject(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Future<int?> getInt(String key) async {
    final v = await get(key);
    return v == null ? null : int.tryParse(v);
  }

  Stream<int?> watchInt(String key) =>
      watch(key).map((v) => v == null ? null : int.tryParse(v));

  Future<void> setInt(String key, int? value) =>
      set(key, value == null ? '' : '$value');
}
