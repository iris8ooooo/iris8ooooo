import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/rate_resolver.dart';
import 'package:gongsu_ledger/domain/settlement.dart';
import 'package:gongsu_ledger/domain/stats.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/domain/tax_rates.dart';

void main() {
  test('연간 통계: 월별 분배·연 합계·업체별 합산', () {
    const histories = <RateHistoryEntry>[
      (siteId: 1, effectiveFromDateKey: 20000101, dailyRateWon: 100000),
    ];
    final entries = <SettlementEntry>[
      (
        dateKey: 20260105,
        centiGongsu: 100,
        siteId: 1,
        unitRateWonOverride: null,
      ),
      (
        dateKey: 20260106,
        centiGongsu: 150,
        siteId: 1,
        unitRateWonOverride: null,
      ),
      (
        dateKey: 20260315,
        centiGongsu: 200,
        siteId: 1,
        unitRateWonOverride: null,
      ),
      (
        dateKey: 20261231,
        centiGongsu: 100,
        siteId: null,
        unitRateWonOverride: null,
      ),
      (
        dateKey: 20250101,
        centiGongsu: 100,
        siteId: 1,
        unitRateWonOverride: null,
      ), // 다른 해
    ];
    final stats = buildYearStats(
      year: 2026,
      entries: entries,
      items: const [],
      histories: histories,
      taxBySite: const {
        1: (mode: TaxMode.withholding33, options: TaxOptions.defaults),
      },
      ratesForYear: defaultTaxRateTable,
      rounding: TaxRounding.floor10,
    );
    expect(stats.months.length, 12);
    expect(stats.months[0].centi, 250);
    expect(stats.months[0].workedDays, 2);
    expect(stats.months[2].centi, 200);
    expect(stats.months[11].centi, 100);
    expect(stats.months[1].centi, 0);
    expect(stats.totalCenti, 550);
    expect(stats.totalWorkedDays, 4);
    expect(stats.grossWon, 450000);
    expect(stats.netWon, 450000 - 14850); // 3.3%
    expect(stats.maxMonthCenti, 250);
    expect(stats.hasMoney, true);

    expect(stats.sites.map((s) => s.siteId).toList(), [1, null]);
    expect(stats.sites[0].centi, 450);
    expect(stats.sites[0].grossWon, 450000);
    expect(stats.sites[1].centi, 100);
  });

  test('기록이 없으면 전부 0, 금액 없음', () {
    final stats = buildYearStats(
      year: 2026,
      entries: const [],
      items: const [],
      histories: const [],
      taxBySite: const {},
      ratesForYear: defaultTaxRateTable,
      rounding: TaxRounding.floor10,
    );
    expect(stats.totalCenti, 0);
    expect(stats.hasMoney, false);
    expect(stats.sites, isEmpty);
  });
}
