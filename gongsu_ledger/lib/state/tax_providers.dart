import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/day_item_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/month_grid.dart';
import '../domain/rate_resolver.dart';
import '../domain/settlement.dart';
import '../domain/stats.dart';
import '../domain/tax_engine.dart';
import '../domain/tax_rates.dart';
import 'calendar_providers.dart';
import 'db_providers.dart';
import 'site_providers.dart';

/// 세금 끝전 처리 방식 (설정). 기본 10원 미만 절사.
final taxRoundingProvider = StreamProvider.autoDispose<TaxRounding>((ref) {
  return ref
      .watch(settingsRepoProvider)
      .watch(SettingsRepository.keyTaxRounding)
      .map(TaxRounding.fromCode);
});

/// 정산 마감 주기 시작일 (1~28). 1 = 달력 월 그대로.
final settleCycleStartDayProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(settingsRepoProvider)
      .watchInt(SettingsRepository.keySettleCycleStartDay)
      .map((v) => v == null || v < 1 || v > 28 ? 1 : v);
});

/// 연도별 세율 테이블 = 기본 상수 + 사용자 오버라이드 병합.
final taxRatesProvider = StreamProvider.autoDispose.family<TaxRateTable, int>((
  ref,
  year,
) {
  return ref.watch(settingsRepoProvider).watchTaxRatesOverride(year).map((
    json,
  ) {
    final base = defaultTaxRateTable(year);
    return json == null ? base : base.mergeJson(json);
  });
});

/// 업체별 세금 설정 (보관 업체 포함 — 과거 기록 정산에 필요).
final taxBySiteProvider = Provider.autoDispose<Map<int, SiteTaxConfig>>((ref) {
  final sites = ref.watch(allSitesProvider).valueOrNull ?? const <Site>[];
  return {
    for (final s in sites)
      s.id: (
        mode: TaxMode.fromCode(s.taxMode),
        options: TaxOptions.fromJsonString(s.taxOptionsJson),
      ),
  };
});

List<RateHistoryEntry> _rateEntries(List<SiteRateHistory> rows) => [
  for (final r in rows)
    (
      siteId: r.siteId,
      effectiveFromDateKey: r.effectiveFromDateKey,
      dailyRateWon: r.dailyRateWon,
    ),
];

List<SettlementEntry> _settlementEntries(Iterable<WorkEntry> rows) => [
  for (final w in rows)
    (
      dateKey: w.dateKey,
      centiGongsu: w.centiGongsu,
      siteId: w.siteId,
      unitRateWonOverride: w.unitRateWonOverride,
    ),
];

List<SettlementItem> _settlementItems(Iterable<DayExtraItem> rows) => [
  for (final it in rows)
    (
      dateKey: it.dateKey,
      siteId: it.siteId,
      isDeduction: ExtraItemKind.fromCode(it.kind) == ExtraItemKind.deduction,
      isTaxable: it.isTaxable,
      amountWon: it.amountWon,
    ),
];

/// 세율 테이블 조회 함수 — 정산 함수에 넘긴다. 기간의 종료 연도 하나만
/// 구독한다 (정산 함수가 종료일 연도로 계산하므로).
TaxRateTable Function(int) _ratesResolver(Ref ref, int year) {
  final table =
      ref.watch(taxRatesProvider(year)).valueOrNull ??
      defaultTaxRateTable(year);
  return (_) => table;
}

/// 달력에 보이는 달의 정산 — 월 카드 세후 실수령. 월 쿼리(monthEntries/
/// monthExtraItems)를 그대로 재사용해 추가 쿼리가 없다.
final monthSettlementProvider = Provider.autoDispose
    .family<PeriodSettlement, int>((ref, ym) {
      final fromKey = ym * 100 + 1;
      final toKey = ym * 100 + 31;
      final byDay = ref.watch(monthEntriesProvider(ym)).valueOrNull;
      if (byDay == null) return PeriodSettlement.empty(fromKey, toKey);
      final itemsByDay =
          ref.watch(monthExtraItemsProvider(ym)).valueOrNull ??
          const <int, List<DayExtraItem>>{};
      final rates =
          ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
      return buildPeriodSettlement(
        fromKey: fromKey,
        toKey: toKey,
        entries: _settlementEntries(byDay.values.expand((l) => l)),
        items: _settlementItems(itemsByDay.values.expand((l) => l)),
        histories: _rateEntries(rates),
        taxBySite: ref.watch(taxBySiteProvider),
        ratesForYear: _ratesResolver(ref, yearOfYm(ym)),
        rounding:
            ref.watch(taxRoundingProvider).valueOrNull ?? TaxRounding.floor10,
      );
    });

/// 기간 키: from × 1e8 + to (family 키는 int 규칙).
int periodKey(int fromKey, int toKey) => fromKey * 100000000 + toKey;

int periodFromKey(int key) => key ~/ 100000000;

int periodToKey(int key) => key % 100000000;

final rangeEntriesProvider = StreamProvider.autoDispose
    .family<List<WorkEntry>, int>((ref, key) {
      return ref
          .watch(databaseProvider)
          .workEntryDao
          .watchRange(periodFromKey(key), periodToKey(key));
    });

final rangeItemsProvider = StreamProvider.autoDispose
    .family<List<DayExtraItem>, int>((ref, key) {
      return ref
          .watch(databaseProvider)
          .dayItemDao
          .watchRange(periodFromKey(key), periodToKey(key));
    });

/// 기간의 메모 (확인서 PDF용). 키는 [periodKey].
final rangeMemosProvider = FutureProvider.autoDispose
    .family<List<DayMemo>, int>((ref, key) {
      return ref
          .watch(databaseProvider)
          .memoDao
          .getRange(periodFromKey(key), periodToKey(key));
    });

/// 임의 기간 정산 (정산 화면). 키는 [periodKey].
final periodSettlementProvider = Provider.autoDispose
    .family<PeriodSettlement?, int>((ref, key) {
      final fromKey = periodFromKey(key);
      final toKey = periodToKey(key);
      final entries = ref.watch(rangeEntriesProvider(key)).valueOrNull;
      final items = ref.watch(rangeItemsProvider(key)).valueOrNull;
      if (entries == null || items == null) return null; // 로딩 중
      final rates =
          ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
      return buildPeriodSettlement(
        fromKey: fromKey,
        toKey: toKey,
        entries: _settlementEntries(entries),
        items: _settlementItems(items),
        histories: _rateEntries(rates),
        taxBySite: ref.watch(taxBySiteProvider),
        ratesForYear: _ratesResolver(ref, toKey ~/ 10000),
        rounding:
            ref.watch(taxRoundingProvider).valueOrNull ?? TaxRounding.floor10,
      );
    });

/// 연간 통계 (통계 화면). null = 로딩 중.
final yearStatsProvider = Provider.autoDispose.family<YearStats?, int>((
  ref,
  year,
) {
  final key = periodKey(year * 10000 + 101, year * 10000 + 1231);
  final entries = ref.watch(rangeEntriesProvider(key)).valueOrNull;
  final items = ref.watch(rangeItemsProvider(key)).valueOrNull;
  if (entries == null || items == null) return null;
  final rates =
      ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
  return buildYearStats(
    year: year,
    entries: _settlementEntries(entries),
    items: _settlementItems(items),
    histories: _rateEntries(rates),
    taxBySite: ref.watch(taxBySiteProvider),
    ratesForYear: _ratesResolver(ref, year),
    rounding: ref.watch(taxRoundingProvider).valueOrNull ?? TaxRounding.floor10,
  );
});
