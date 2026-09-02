import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/rate_resolver.dart';
import 'package:gongsu_ledger/domain/settlement.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/domain/tax_rates.dart';

void main() {
  const histories = <RateHistoryEntry>[
    (siteId: 1, effectiveFromDateKey: 20000101, dailyRateWon: 150000),
    (siteId: 2, effectiveFromDateKey: 20000101, dailyRateWon: 200000),
  ];
  const taxBySite = <int, SiteTaxConfig>{
    1: (mode: TaxMode.withholding33, options: TaxOptions.defaults),
    2: (mode: TaxMode.insurance4, options: TaxOptions.defaults),
  };

  final entries = <SettlementEntry>[
    // 업체 1: 9/1~9/5 1공수씩 (3.3%)
    for (var d = 1; d <= 5; d++)
      (
        dateKey: 20260900 + d,
        centiGongsu: 100,
        siteId: 1,
        unitRateWonOverride: null,
      ),
    // 업체 2: 9/1~9/8 1공수씩 (4대보험, 8일 → 연금·건강 적용)
    for (var d = 1; d <= 8; d++)
      (
        dateKey: 20260900 + d,
        centiGongsu: 100,
        siteId: 2,
        unitRateWonOverride: null,
      ),
    // 업체 미지정 1.5공수 (단가 없음 → 금액 제외)
    (
      dateKey: 20260910,
      centiGongsu: 150,
      siteId: null,
      unitRateWonOverride: null,
    ),
    // 기간 밖 (8/31) — 제외되어야 함
    (dateKey: 20260831, centiGongsu: 100, siteId: 1, unitRateWonOverride: null),
  ];
  final items = <SettlementItem>[
    (
      dateKey: 20260901,
      siteId: 1,
      isDeduction: false,
      isTaxable: false,
      amountWon: 10000,
    ),
    (
      dateKey: 20260902,
      siteId: 1,
      isDeduction: true,
      isTaxable: false,
      amountWon: 5000,
    ),
    (
      dateKey: 20260901,
      siteId: 2,
      isDeduction: false,
      isTaxable: true,
      amountWon: 50000,
    ),
    (
      dateKey: 20261001,
      siteId: 2,
      isDeduction: false,
      isTaxable: false,
      amountWon: 99999,
    ), // 기간 밖
  ];

  PeriodSettlement build() => buildPeriodSettlement(
    fromKey: 20260901,
    toKey: 20260930,
    entries: entries,
    items: items,
    histories: histories,
    taxBySite: taxBySite,
    ratesForYear: defaultTaxRateTable,
    rounding: TaxRounding.floor10,
  );

  test('업체별 분리 + 정렬(업체 미지정 마지막) + 기간 필터', () {
    final s = build();
    expect(s.sites.map((x) => x.siteId).toList(), [1, 2, null]);
    expect(s.totalCenti, 500 + 800 + 150);
    expect(s.workedDays, 9); // 9/1~9/8 + 9/10
    expect(s.unpricedCenti, 150);
  });

  test('업체 1 (3.3%): 세전 755,000 / 세금 24,750 / 실수령 730,250', () {
    final a = build().sites[0];
    expect(a.laborWon, 750000);
    expect(a.allowanceWon, 10000);
    expect(a.deductionWon, 5000);
    expect(a.grossWon, 755000);
    expect(a.taxableBaseWon, 750000); // 비과세 식비는 과세기준에서 제외
    expect(a.tax.incomeTaxWon, 22500);
    expect(a.tax.localIncomeTaxWon, 2250);
    expect(a.netWon, 730250);
    expect(a.workedDays, 5);
  });

  test('업체 2 (4대보험 8일): 과세 가산항목 포함, 일용근로소득세 일자별', () {
    final b = build().sites[1];
    expect(b.laborWon, 1600000);
    expect(b.taxableAllowanceWon, 50000);
    expect(b.taxableBaseWon, 1650000);
    expect(b.grossWon, 1650000);
    expect(b.tax.employmentWon, 14850);
    expect(b.tax.pensionWon, 78370);
    expect(b.tax.healthWon, 59310);
    expect(b.tax.longTermCareWon, 7680);
    // 9/1: 250,000 → 2,700 / 지방 270. 9/2~9/8: 200,000 → 1,350 / 130 × 7
    expect(b.tax.incomeTaxWon, 2700 + 1350 * 7);
    expect(b.tax.localIncomeTaxWon, 270 + 130 * 7);
    expect(b.tax.totalWon, 173540);
    expect(b.netWon, 1650000 - 173540);
  });

  test('업체 미지정 묶음은 세금 없음, 금액도 없음', () {
    final n = build().sites[2];
    expect(n.taxMode, TaxMode.none);
    expect(n.tax.isZero, true);
    expect(n.grossWon, 0);
    expect(n.unpricedCenti, 150);
    expect(n.hasMoney, true); // 단가 없는 공수 안내를 위해
  });

  test('합계: 세전 2,405,000 / 세금 198,290 / 실수령 2,206,710', () {
    final s = build();
    expect(s.grossWon, 2405000);
    expect(s.tax.totalWon, 198290);
    expect(s.netWon, 2206710);
    expect(s.hasMoney, true);
    expect(s.hasTaxConfigured, true);
  });

  test('기록 없는 기간은 빈 정산', () {
    final s = buildPeriodSettlement(
      fromKey: 20270101,
      toKey: 20270131,
      entries: entries,
      items: items,
      histories: histories,
      taxBySite: taxBySite,
      ratesForYear: defaultTaxRateTable,
      rounding: TaxRounding.floor10,
    );
    expect(s.sites, isEmpty);
    expect(s.hasMoney, false);
    expect(s.netWon, 0);
  });

  test('4대보험 업체가 7일만 일하면 연금·건강 없이 고용보험만', () {
    final s = buildPeriodSettlement(
      fromKey: 20260901,
      toKey: 20260907,
      entries: entries,
      items: const [],
      histories: histories,
      taxBySite: taxBySite,
      ratesForYear: defaultTaxRateTable,
      rounding: TaxRounding.floor10,
    );
    final b = s.sites.singleWhere((x) => x.siteId == 2);
    expect(b.workedDays, 7);
    expect(b.tax.pensionWon, 0);
    expect(b.tax.healthWon, 0);
    expect(b.tax.employmentWon, 12600); // 1,400,000 × 0.9%
  });

  test('마감 주기(전월 21일~당월 20일) 같은 임의 기간도 같은 함수로', () {
    final s = buildPeriodSettlement(
      fromKey: 20260821,
      toKey: 20260920,
      entries: entries,
      items: items,
      histories: histories,
      taxBySite: taxBySite,
      ratesForYear: defaultTaxRateTable,
      rounding: TaxRounding.floor10,
    );
    // 8/31 기록이 이번엔 포함된다
    final a = s.sites.singleWhere((x) => x.siteId == 1);
    expect(a.centi, 600);
    expect(a.laborWon, 900000);
  });
}
