/// 연간 통계 — 월별 추이, 연간 누적(연봉 뷰), 업체별 합산.
/// 전부 [buildPeriodSettlement]에서 파생해 다른 화면과 숫자가 일치한다.
library;

import 'month_grid.dart';
import 'rate_resolver.dart';
import 'settlement.dart';
import 'tax_engine.dart';
import 'tax_rates.dart';

class MonthStat {
  const MonthStat({
    required this.ym,
    required this.centi,
    required this.workedDays,
    required this.grossWon,
    required this.netWon,
    required this.hasMoney,
  });

  final int ym;
  final int centi;
  final int workedDays;
  final int grossWon;
  final int netWon;
  final bool hasMoney;
}

class SiteYearStat {
  const SiteYearStat({
    required this.siteId,
    required this.centi,
    required this.workedDays,
    required this.grossWon,
    required this.netWon,
  });

  final int? siteId;
  final int centi;
  final int workedDays;
  final int grossWon;
  final int netWon;
}

class YearStats {
  const YearStats({
    required this.year,
    required this.months,
    required this.sites,
  });

  final int year;

  /// 1월부터 12월까지 12개.
  final List<MonthStat> months;
  final List<SiteYearStat> sites;

  int get totalCenti => months.fold(0, (s, m) => s + m.centi);
  int get totalWorkedDays => months.fold(0, (s, m) => s + m.workedDays);
  int get grossWon => months.fold(0, (s, m) => s + m.grossWon);
  int get netWon => months.fold(0, (s, m) => s + m.netWon);
  bool get hasMoney => months.any((m) => m.hasMoney);
  int get maxMonthCenti => months.fold(0, (s, m) => m.centi > s ? m.centi : s);
}

YearStats buildYearStats({
  required int year,
  required Iterable<SettlementEntry> entries,
  required Iterable<SettlementItem> items,
  required Iterable<RateHistoryEntry> histories,
  required Map<int, SiteTaxConfig> taxBySite,
  required TaxRateTable Function(int year) ratesForYear,
  required TaxRounding rounding,
}) {
  final entryList = entries.toList();
  final itemList = items.toList();
  final histList = histories.toList();

  final months = <MonthStat>[];
  final siteCenti = <int?, int>{};
  final siteDays = <int?, int>{};
  final siteGross = <int?, int>{};
  final siteNet = <int?, int>{};

  for (var month = 1; month <= 12; month++) {
    final ym = ymOf(year, month);
    final s = buildPeriodSettlement(
      fromKey: ym * 100 + 1,
      toKey: ym * 100 + 31,
      entries: entryList,
      items: itemList,
      histories: histList,
      taxBySite: taxBySite,
      ratesForYear: ratesForYear,
      rounding: rounding,
    );
    months.add(
      MonthStat(
        ym: ym,
        centi: s.totalCenti,
        workedDays: s.workedDays,
        grossWon: s.grossWon,
        netWon: s.netWon,
        hasMoney: s.hasMoney,
      ),
    );
    for (final site in s.sites) {
      siteCenti[site.siteId] = (siteCenti[site.siteId] ?? 0) + site.centi;
      siteDays[site.siteId] = (siteDays[site.siteId] ?? 0) + site.workedDays;
      siteGross[site.siteId] = (siteGross[site.siteId] ?? 0) + site.grossWon;
      siteNet[site.siteId] = (siteNet[site.siteId] ?? 0) + site.netWon;
    }
  }

  final siteKeys = siteCenti.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });

  return YearStats(
    year: year,
    months: months,
    sites: [
      for (final id in siteKeys)
        SiteYearStat(
          siteId: id,
          centi: siteCenti[id]!,
          workedDays: siteDays[id]!,
          grossWon: siteGross[id]!,
          netWon: siteNet[id]!,
        ),
    ],
  );
}
