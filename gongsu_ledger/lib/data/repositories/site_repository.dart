import 'package:drift/drift.dart';

import '../../domain/marker_palette.dart';
import '../../domain/tax_engine.dart';
import '../../domain/uid.dart';
import '../db/app_database.dart';
import '../db/daos/site_dao.dart';

/// 업체를 만들 때 넣는 "기본 단가"의 적용 시작일. 과거 모든 기록에 적용되도록
/// 충분히 이른 날짜를 쓴다 (백업 검증의 날짜 범위 2000~2100 안).
const int initialRateEffectiveFromDateKey = 20000101;

class SiteRepository {
  SiteRepository(this._dao);

  final SiteDao _dao;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  /// 업체 생성. [dailyRateWon]을 주면 기본 단가 이력을 함께 만든다.
  Future<int> create({
    required String name,
    required int colorId,
    int? dailyRateWon,
    TaxMode taxMode = TaxMode.none,
    TaxOptions taxOptions = TaxOptions.defaults,
  }) async {
    _validateSite(name, colorId);
    final existing = await _dao.getActive();
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final now = _now;
    final siteId = await _dao.insertSite(
      SitesCompanion.insert(
        uid: generateUid(),
        name: name.trim(),
        colorId: Value(colorId),
        sortOrder: nextOrder,
        createdAtMillis: now,
        updatedAtMillis: now,
        taxMode: Value(taxMode.code),
        taxOptionsJson: Value(taxOptions.toJsonString()),
      ),
    );
    if (dailyRateWon != null) {
      await setRate(
        siteId: siteId,
        effectiveFromDateKey: initialRateEffectiveFromDateKey,
        dailyRateWon: dailyRateWon,
      );
    }
    return siteId;
  }

  Future<void> update({
    required int id,
    required String name,
    required int colorId,
  }) {
    _validateSite(name, colorId);
    return _dao.updateSiteFields(
      id,
      SitesCompanion(
        name: Value(name.trim()),
        colorId: Value(colorId),
        updatedAtMillis: Value(_now),
      ),
    );
  }

  /// 세금 방식/옵션 변경. 과거 기록의 실수령도 이 설정으로 다시 계산된다
  /// (세금은 저장하지 않고 조회 시점에 계산하므로).
  Future<void> updateTax({
    required int id,
    required TaxMode mode,
    required TaxOptions options,
  }) => _dao.updateSiteFields(
    id,
    SitesCompanion(
      taxMode: Value(mode.code),
      taxOptionsJson: Value(options.toJsonString()),
      updatedAtMillis: Value(_now),
    ),
  );

  /// 삭제 대신 보관 — 과거 기록의 업체명/색 표시는 유지된다.
  Future<void> archive(int id) => _dao.archive(id, _now);

  Future<void> reorder(List<int> orderedIds) => _dao.reorder(orderedIds, _now);

  /// 단가 개정. 같은 업체·같은 적용 시작일의 살아있는 이력이 있으면 그 행을
  /// 갱신한다(중복 이력 방지) — 과거 다른 시작일의 이력은 절대 건드리지 않는다.
  Future<int> setRate({
    required int siteId,
    required int effectiveFromDateKey,
    required int dailyRateWon,
  }) async {
    _validateRate(effectiveFromDateKey, dailyRateWon);
    final now = _now;
    final existing = await _dao.getRatesOfSite(siteId);
    for (final r in existing) {
      if (r.effectiveFromDateKey == effectiveFromDateKey) {
        await _dao.updateRateFields(
          r.id,
          SiteRateHistoriesCompanion(
            dailyRateWon: Value(dailyRateWon),
            updatedAtMillis: Value(now),
          ),
        );
        return r.id;
      }
    }
    return _dao.insertRate(
      SiteRateHistoriesCompanion.insert(
        uid: generateUid(),
        siteId: siteId,
        effectiveFromDateKey: effectiveFromDateKey,
        dailyRateWon: dailyRateWon,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );
  }

  Future<void> updateRate({
    required int id,
    required int effectiveFromDateKey,
    required int dailyRateWon,
  }) {
    _validateRate(effectiveFromDateKey, dailyRateWon);
    return _dao.updateRateFields(
      id,
      SiteRateHistoriesCompanion(
        effectiveFromDateKey: Value(effectiveFromDateKey),
        dailyRateWon: Value(dailyRateWon),
        updatedAtMillis: Value(_now),
      ),
    );
  }

  Future<void> deleteRate(int id) => _dao.softDeleteRate(id, _now);

  void _validateSite(String name, int colorId) {
    if (name.trim().isEmpty || name.trim().length > 30) {
      throw ArgumentError.value(name, 'name', '업체 이름은 1~30자');
    }
    if (colorId < 0 || colorId >= MarkerPalette.entries.length) {
      throw ArgumentError.value(colorId, 'colorId', '팔레트 범위 밖');
    }
  }

  void _validateRate(int effectiveFromDateKey, int dailyRateWon) {
    if (dailyRateWon < 0) {
      throw ArgumentError.value(dailyRateWon, 'dailyRateWon', '단가는 0 이상');
    }
    final year = effectiveFromDateKey ~/ 10000;
    final month = (effectiveFromDateKey % 10000) ~/ 100;
    final day = effectiveFromDateKey % 100;
    if (year < 2000 ||
        year > 2100 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      throw ArgumentError.value(
        effectiveFromDateKey,
        'effectiveFromDateKey',
        '날짜 키 범위 밖',
      );
    }
  }
}
