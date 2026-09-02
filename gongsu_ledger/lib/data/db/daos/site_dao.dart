import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'site_dao.g.dart';

/// 업체 + 단가 이력 DAO.
///
/// 단가 이력 읽기는 [_aliveRates]를 거친다 (soft delete 필터 단일 진입점).
@DriftAccessor(tables: [Sites, SiteRateHistories])
class SiteDao extends DatabaseAccessor<AppDatabase> with _$SiteDaoMixin {
  SiteDao(super.db);

  // ── 업체 ──────────────────────────────────────────────

  Stream<List<Site>> watchActive() =>
      (select(sites)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<List<Site>> getActive() =>
      (select(sites)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// 보관 포함 전체 — 과거 기록의 업체명/색 표시용.
  Stream<List<Site>> watchAll() => select(sites).watch();

  Future<Site?> getById(int id) =>
      (select(sites)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertSite(SitesCompanion site) => into(sites).insert(site);

  Future<void> updateSiteFields(int id, SitesCompanion changes) =>
      (update(sites)..where((t) => t.id.equals(id))).write(changes);

  Future<void> archive(int id, int nowMillis) => updateSiteFields(
    id,
    SitesCompanion(
      isArchived: const Value(true),
      updatedAtMillis: Value(nowMillis),
    ),
  );

  Future<void> reorder(List<int> orderedIds, int nowMillis) =>
      transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await updateSiteFields(
            orderedIds[i],
            SitesCompanion(
              sortOrder: Value(i),
              updatedAtMillis: Value(nowMillis),
            ),
          );
        }
      });

  // ── 단가 이력 ─────────────────────────────────────────

  SimpleSelectStatement<$SiteRateHistoriesTable, SiteRateHistory>
  _aliveRates() =>
      select(siteRateHistories)..where((t) => t.deletedAtMillis.isNull());

  /// 전체 살아있는 단가 이력 — 월 정산 계산은 이 스트림 하나로 모든 업체를
  /// 해석한다 (업체 수가 적어 전량 구독이 가장 단순하고 빠르다).
  Stream<List<SiteRateHistory>> watchAllRates() =>
      (_aliveRates()..orderBy([
            (t) => OrderingTerm.asc(t.siteId),
            (t) => OrderingTerm.asc(t.effectiveFromDateKey),
          ]))
          .watch();

  Stream<List<SiteRateHistory>> watchRatesOfSite(int siteId) =>
      (_aliveRates()
            ..where((t) => t.siteId.equals(siteId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveFromDateKey)]))
          .watch();

  Future<List<SiteRateHistory>> getRatesOfSite(int siteId) =>
      (_aliveRates()
            ..where((t) => t.siteId.equals(siteId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveFromDateKey)]))
          .get();

  Future<int> insertRate(SiteRateHistoriesCompanion rate) =>
      into(siteRateHistories).insert(rate);

  Future<void> updateRateFields(int id, SiteRateHistoriesCompanion changes) =>
      (update(siteRateHistories)..where((t) => t.id.equals(id))).write(changes);

  Future<void> softDeleteRate(int id, int nowMillis) => updateRateFields(
    id,
    SiteRateHistoriesCompanion(
      deletedAtMillis: Value(nowMillis),
      updatedAtMillis: Value(nowMillis),
    ),
  );
}
