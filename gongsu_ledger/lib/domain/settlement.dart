/// 기간 정산 — 임의 기간(예: 전월 21일~당월 20일)의 업체별 공수·금액·공제.
///
/// 월 카드(한 달), 정산 화면(임의 기간), 통계(연간 월별) 전부 이 하나의
/// 순수 함수로 계산해 숫자가 화면마다 어긋나지 않게 한다.
library;

import 'gongsu_value.dart';
import 'rate_resolver.dart';
import 'tax_engine.dart';
import 'tax_rates.dart';

typedef SettlementEntry = ({
  int dateKey,
  int centiGongsu,
  int? siteId,
  int? unitRateWonOverride,
});

typedef SettlementItem = ({
  int dateKey,
  int? siteId,
  bool isDeduction,
  bool isTaxable,
  int amountWon,
});

typedef SiteTaxConfig = ({TaxMode mode, TaxOptions options});

/// 업체 하나(또는 업체 미지정 묶음)의 정산.
class SiteSettlement {
  const SiteSettlement({
    required this.siteId,
    required this.taxMode,
    required this.centi,
    required this.unpricedCenti,
    required this.workedDays,
    required this.entryCount,
    required this.laborWon,
    required this.allowanceWon,
    required this.taxableAllowanceWon,
    required this.deductionWon,
    required this.tax,
  });

  /// null = 업체 미지정 기록/항목 묶음.
  final int? siteId;
  final TaxMode taxMode;
  final int centi;

  /// 단가 미설정이라 금액에 못 넣은 공수.
  final int unpricedCenti;
  final int workedDays;
  final int entryCount;
  final int laborWon;
  final int allowanceWon;
  final int taxableAllowanceWon;
  final int deductionWon;
  final TaxBreakdown tax;

  int get grossWon => laborWon + allowanceWon - deductionWon;
  int get taxableBaseWon => laborWon + taxableAllowanceWon;
  int get netWon => grossWon - tax.totalWon;

  /// 금액 정보가 하나라도 있는가 (없으면 UI가 금액 줄을 숨긴다).
  bool get hasMoney =>
      laborWon > 0 || allowanceWon > 0 || deductionWon > 0 || unpricedCenti > 0;
}

class PeriodSettlement {
  const PeriodSettlement({
    required this.fromKey,
    required this.toKey,
    required this.sites,
    required this.totalCenti,
    required this.workedDays,
    required this.unpricedCenti,
    required this.grossWon,
    required this.tax,
  });

  final int fromKey;
  final int toKey;

  /// siteId 오름차순, 업체 미지정(null)은 마지막.
  final List<SiteSettlement> sites;
  final int totalCenti;

  /// 기간 중 공수 > 0인 날의 수 (업체 중복 없이).
  final int workedDays;
  final int unpricedCenti;
  final int grossWon;
  final TaxBreakdown tax;

  int get netWon => grossWon - tax.totalWon;

  bool get hasMoney => sites.any((s) => s.hasMoney);

  /// 세금 방식이 설정된 업체가 하나라도 있는가.
  bool get hasTaxConfigured => sites.any((s) => s.taxMode != TaxMode.none);

  static PeriodSettlement empty(int fromKey, int toKey) => PeriodSettlement(
    fromKey: fromKey,
    toKey: toKey,
    sites: const [],
    totalCenti: 0,
    workedDays: 0,
    unpricedCenti: 0,
    grossWon: 0,
    tax: TaxBreakdown.zero,
  );
}

class _SiteAccumulator {
  int centi = 0;
  int unpricedCenti = 0;
  int entryCount = 0;
  int laborWon = 0;
  int allowanceWon = 0;
  int taxableAllowanceWon = 0;
  int deductionWon = 0;
  final Set<int> workedDayKeys = {};
  final Map<int, int> laborByDay = {};
  final Map<int, int> taxableAllowanceByDay = {};
}

/// 기간 정산 계산. 입력은 이미 기간 밖 행이 섞여 있어도 되며 여기서 거른다.
PeriodSettlement buildPeriodSettlement({
  required int fromKey,
  required int toKey,
  required Iterable<SettlementEntry> entries,
  required Iterable<SettlementItem> items,
  required Iterable<RateHistoryEntry> histories,
  required Map<int, SiteTaxConfig> taxBySite,
  required TaxRateTable Function(int year) ratesForYear,
  required TaxRounding rounding,
}) {
  assert(fromKey <= toKey);
  final acc = <int?, _SiteAccumulator>{};
  final allWorkedDays = <int>{};
  final histList = histories.toList();

  for (final e in entries) {
    if (e.dateKey < fromKey || e.dateKey > toKey) continue;
    assert(e.centiGongsu >= 0);
    final a = acc.putIfAbsent(e.siteId, _SiteAccumulator.new);
    a.centi += e.centiGongsu;
    a.entryCount++;
    if (e.centiGongsu > 0) {
      a.workedDayKeys.add(e.dateKey);
      allWorkedDays.add(e.dateKey);
    }
    final rate = resolveEntryRateWon(
      dateKey: e.dateKey,
      siteId: e.siteId,
      unitRateWonOverride: e.unitRateWonOverride,
      histories: histList,
    );
    if (rate == null) {
      a.unpricedCenti += e.centiGongsu;
      continue;
    }
    final won = calcAmountWon(centiGongsu: e.centiGongsu, dailyRateWon: rate);
    a.laborWon += won;
    a.laborByDay[e.dateKey] = (a.laborByDay[e.dateKey] ?? 0) + won;
  }

  for (final it in items) {
    if (it.dateKey < fromKey || it.dateKey > toKey) continue;
    assert(it.amountWon >= 0);
    final a = acc.putIfAbsent(it.siteId, _SiteAccumulator.new);
    if (it.isDeduction) {
      a.deductionWon += it.amountWon;
    } else {
      a.allowanceWon += it.amountWon;
      if (it.isTaxable) {
        a.taxableAllowanceWon += it.amountWon;
        a.taxableAllowanceByDay[it.dateKey] =
            (a.taxableAllowanceByDay[it.dateKey] ?? 0) + it.amountWon;
      }
    }
  }

  final rates = ratesForYear(toKey ~/ 10000);
  final sites = <SiteSettlement>[];
  var totalCenti = 0;
  var unpriced = 0;
  var gross = 0;
  var tax = TaxBreakdown.zero;

  final keys = acc.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });

  for (final siteId in keys) {
    final a = acc[siteId]!;
    final config = siteId == null ? null : taxBySite[siteId];
    final mode = config?.mode ?? TaxMode.none;
    final dayKeys = {...a.laborByDay.keys, ...a.taxableAllowanceByDay.keys};
    final dailyTaxable = [
      for (final d in dayKeys)
        (a.laborByDay[d] ?? 0) + (a.taxableAllowanceByDay[d] ?? 0),
    ];
    final siteTax = computeTax(
      mode: mode,
      options: config?.options ?? TaxOptions.defaults,
      rates: rates,
      rounding: rounding,
      taxableBaseWon: a.laborWon + a.taxableAllowanceWon,
      dailyTaxableWon: dailyTaxable,
      workedDays: a.workedDayKeys.length,
    );
    final s = SiteSettlement(
      siteId: siteId,
      taxMode: mode,
      centi: a.centi,
      unpricedCenti: a.unpricedCenti,
      workedDays: a.workedDayKeys.length,
      entryCount: a.entryCount,
      laborWon: a.laborWon,
      allowanceWon: a.allowanceWon,
      taxableAllowanceWon: a.taxableAllowanceWon,
      deductionWon: a.deductionWon,
      tax: siteTax,
    );
    sites.add(s);
    totalCenti += s.centi;
    unpriced += s.unpricedCenti;
    gross += s.grossWon;
    tax = tax + siteTax;
  }

  return PeriodSettlement(
    fromKey: fromKey,
    toKey: toKey,
    sites: sites,
    totalCenti: totalCenti,
    workedDays: allWorkedDays.length,
    unpricedCenti: unpriced,
    grossWon: gross,
    tax: tax,
  );
}
