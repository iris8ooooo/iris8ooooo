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

  /// 달(yyyyMM)별 근무일 — 기간 밖 행도 포함한다. 4대보험 "월 8일 이상" 판정은
  /// 정산 기간이 아니라 달력상의 달 전체가 기준이기 때문이다.
  final Map<int, Set<int>> monthWorkedDayKeys = {};
}

/// 기간 정산 계산. 입력은 기간 밖 행이 섞여 있어도 된다 — 금액은 기간 안 행만
/// 더하고, 기간 밖 행은 4대보험의 월 근무일 판정에만 쓴다 (호출자는 기간이 걸친
/// 달 전체의 기록을 넘기는 것이 좋다; 안 넘기면 기간 안 근무일만으로 판정).
///
/// 4대보험(국민연금·건강·장기요양·고용·일용소득세)은 달마다 따로 계산해 합산한다
/// — 상·하한과 8일 판정이 달 단위 규칙이라 마감 주기(예: 21일~20일)처럼 두 달에
/// 걸친 기간을 한 덩어리로 계산하면 틀린다. 3.3%는 지급 단위 비례라 기간 전체로.
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
    assert(e.centiGongsu >= 0);
    final a = acc.putIfAbsent(e.siteId, _SiteAccumulator.new);
    if (e.centiGongsu > 0) {
      a.monthWorkedDayKeys
          .putIfAbsent(e.dateKey ~/ 100, () => <int>{})
          .add(e.dateKey);
    }
    if (e.dateKey < fromKey || e.dateKey > toKey) continue;
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

  final endRates = ratesForYear(toKey ~/ 10000);
  final endMonth = (toKey ~/ 100) % 100;
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
    // 기간 밖 행만 있는 업체(월 판정용 문맥)는 정산 목록에 넣지 않는다.
    if (a.entryCount == 0 && a.allowanceWon == 0 && a.deductionWon == 0) {
      continue;
    }
    final config = siteId == null ? null : taxBySite[siteId];
    final mode = config?.mode ?? TaxMode.none;
    final options = config?.options ?? TaxOptions.defaults;
    final dayKeys = {...a.laborByDay.keys, ...a.taxableAllowanceByDay.keys};
    int taxableOf(int d) =>
        (a.laborByDay[d] ?? 0) + (a.taxableAllowanceByDay[d] ?? 0);

    TaxBreakdown siteTax;
    if (mode == TaxMode.insurance4) {
      // 달별로 잘라 계산 — 상·하한, 8일 판정, 연도별 요율이 전부 달 단위.
      final byMonth = <int, List<int>>{};
      for (final d in dayKeys) {
        byMonth.putIfAbsent(d ~/ 100, () => []).add(d);
      }
      siteTax = TaxBreakdown.zero;
      final months = byMonth.keys.toList()..sort();
      for (final ym in months) {
        final days = byMonth[ym]!;
        final daily = [for (final d in days) taxableOf(d)];
        siteTax =
            siteTax +
            computeTax(
              mode: mode,
              options: options,
              rates: ratesForYear(ym ~/ 100),
              rounding: rounding,
              taxableBaseWon: daily.fold(0, (s, v) => s + v),
              dailyTaxableWon: daily,
              workedDays: a.monthWorkedDayKeys[ym]?.length ?? 0,
              month: ym % 100,
            );
      }
    } else {
      siteTax = computeTax(
        mode: mode,
        options: options,
        rates: endRates,
        rounding: rounding,
        taxableBaseWon: a.laborWon + a.taxableAllowanceWon,
        dailyTaxableWon: [for (final d in dayKeys) taxableOf(d)],
        workedDays: a.workedDayKeys.length,
        month: endMonth,
      );
    }
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
