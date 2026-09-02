import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/settlement.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/domain/tax_rates.dart';
import 'package:gongsu_ledger/domain/widget_payload.dart';

void main() {
  final now = DateTime(2026, 9, 2, 14, 5);

  PeriodSettlement settle({
    required List<SettlementEntry> entries,
    Map<int, SiteTaxConfig> taxBySite = const {},
  }) => buildPeriodSettlement(
    fromKey: 20260901,
    toKey: 20260930,
    entries: entries,
    items: const [],
    histories: const [
      (siteId: 1, effectiveFromDateKey: 20000101, dailyRateWon: 180000),
    ],
    taxBySite: taxBySite,
    ratesForYear: defaultTaxRateTable,
    rounding: TaxRounding.floor10,
  );

  group('buildWidgetPayload', () {
    test('기록 없음: 0 공수, 금액 줄 비움', () {
      final p = buildWidgetPayload(
        ym: 202609,
        settlement: PeriodSettlement.empty(20260901, 20260930),
        now: now,
      );
      expect(p[WidgetKeys.monthLabel], '9월');
      expect(p[WidgetKeys.gongsu], '0');
      expect(p[WidgetKeys.workedDays], '0');
      expect(p[WidgetKeys.moneyLabel], '');
      expect(p[WidgetKeys.money], '');
      expect(p[WidgetKeys.updatedAt], '9/2 14:05');
      expect(p.keys.toSet(), WidgetKeys.all.toSet());
    });

    test('단가 없는 기록: 공수는 반올림 없이, 금액 줄은 비움', () {
      final s = settle(
        entries: const [
          (
            dateKey: 20260901,
            centiGongsu: 180,
            siteId: null,
            unitRateWonOverride: null,
          ),
          (
            dateKey: 20260902,
            centiGongsu: 105,
            siteId: null,
            unitRateWonOverride: null,
          ),
        ],
      );
      final p = buildWidgetPayload(ym: 202609, settlement: s, now: now);
      expect(p[WidgetKeys.gongsu], '2.85');
      expect(p[WidgetKeys.workedDays], '2');
      expect(p[WidgetKeys.money], '');
    });

    test('세금 미설정 업체: 세전 금액', () {
      final s = settle(
        entries: const [
          (
            dateKey: 20260901,
            centiGongsu: 150,
            siteId: 1,
            unitRateWonOverride: null,
          ),
        ],
      );
      final p = buildWidgetPayload(ym: 202609, settlement: s, now: now);
      expect(p[WidgetKeys.moneyLabel], '세전');
      expect(p[WidgetKeys.money], '270,000원');
    });

    test('3.3% 업체: 실수령(세후) 금액', () {
      final s = settle(
        entries: const [
          (
            dateKey: 20260901,
            centiGongsu: 100,
            siteId: 1,
            unitRateWonOverride: null,
          ),
        ],
        taxBySite: const {
          1: (mode: TaxMode.withholding33, options: TaxOptions.defaults),
        },
      );
      final p = buildWidgetPayload(ym: 202609, settlement: s, now: now);
      // 180,000 − 소득세 5,400 − 지방소득세 540 = 174,060
      expect(p[WidgetKeys.moneyLabel], '실수령');
      expect(p[WidgetKeys.money], '174,060원');
    });
  });

  group('groupDigits', () {
    test('천 단위 구분', () {
      expect(groupDigits(0), '0');
      expect(groupDigits(999), '999');
      expect(groupDigits(1000), '1,000');
      expect(groupDigits(1234000), '1,234,000');
      expect(groupDigits(5318090), '5,318,090');
      expect(groupDigits(-70000), '-70,000');
    });
  });
}
