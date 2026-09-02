import '../db/app_database.dart';

/// key-value 설정 저장소. 값은 문자열(JSON) — 스키마 변경 없이 확장.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// 입력 시트에서 마지막으로 고른 업체 — 다음 입력의 기본값.
  static const String keyLastSiteId = 'last_site_id';

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
