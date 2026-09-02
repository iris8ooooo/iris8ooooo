import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/domain/tax_rates.dart';

void main() {
  const rates = taxRateTable2026;

  group('3.3% 원천징수', () {
    test('일당 150,000원: 소득세 4,500 + 지방소득세 450', () {
      final t = computeWithholding33(
        taxableBaseWon: 150000,
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.incomeTaxWon, 4500);
      expect(t.localIncomeTaxWon, 450);
      expect(t.totalWon, 4950);
    });

    test('끝전: 10원 미만 절사 vs 원 단위 그대로', () {
      // 175,433 × 3% = 5,262.99 → 정수 5,262 → 절사 5,260. 지방세 526 → 520
      final floored = computeWithholding33(
        taxableBaseWon: 175433,
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(floored.incomeTaxWon, 5260);
      expect(floored.localIncomeTaxWon, 520);
      final exact = computeWithholding33(
        taxableBaseWon: 175433,
        rates: rates,
        rounding: TaxRounding.exact,
      );
      expect(exact.incomeTaxWon, 5262);
      expect(exact.localIncomeTaxWon, 526);
    });

    test('한 달 3,300,000원: 3.3% = 108,900원', () {
      final t = computeWithholding33(
        taxableBaseWon: 3300000,
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.totalWon, 108900);
    });
  });

  group('4대보험 (2026 근로자 부담)', () {
    test(
      '월 3,000,000원·10일 근무: 연금 142,500 / 건강 107,850 / 장기요양 13,960 / 고용 27,000',
      () {
        final t = computeInsurance4(
          month: 9,
          taxableBaseWon: 3000000,
          dailyTaxableWon: const [],
          workedDays: 10,
          options: const TaxOptions(applyDailyIncomeTax: false),
          rates: rates,
          rounding: TaxRounding.floor10,
        );
        expect(t.pensionWon, 142500);
        expect(t.healthWon, 107850);
        expect(t.longTermCareWon, 13960); // 107,850 × 12.95% = 13,966.57 → 절사
        expect(t.employmentWon, 27000);
        expect(t.incomeTaxWon, 0);
        expect(t.totalWon, 142500 + 107850 + 13960 + 27000);
      },
    );

    test('월 8일 미만 근무면 연금·건강·장기요양은 빠지고 고용보험만', () {
      final t = computeInsurance4(
        month: 9,
        taxableBaseWon: 1000000,
        dailyTaxableWon: const [],
        workedDays: 7,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.pensionWon, 0);
      expect(t.healthWon, 0);
      expect(t.longTermCareWon, 0);
      expect(t.employmentWon, 9000);
    });

    test('최소 근무일 0이면 항상 적용', () {
      final t = computeInsurance4(
        month: 9,
        taxableBaseWon: 1000000,
        dailyTaxableWon: const [],
        workedDays: 1,
        options: const TaxOptions(
          pensionHealthMinDays: 0,
          applyDailyIncomeTax: false,
        ),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.pensionWon, 47500);
    });

    test('국민연금 기준소득 상한: 1~6월 6,370,000 / 7월부터 6,590,000', () {
      final t = computeInsurance4(
        month: 6,
        taxableBaseWon: 10000000,
        dailyTaxableWon: const [],
        workedDays: 20,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.pensionWon, 302570); // 6,370,000 × 4.75% = 302,575 → 절사
      expect(t.healthWon, 359500); // 건강보험은 상한 없이 1천만 × 3.595%
      final july = computeInsurance4(
        month: 7,
        taxableBaseWon: 10000000,
        dailyTaxableWon: const [],
        workedDays: 20,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(july.pensionWon, 313020); // 6,590,000 × 4.75% = 313,025 → 절사
    });

    test('국민연금 기준소득 하한(400,000 → 7월부터 410,000) 적용 + 천원 미만 절사', () {
      final t = computeInsurance4(
        month: 6,
        taxableBaseWon: 300000,
        dailyTaxableWon: const [],
        workedDays: 8,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.pensionWon, 19000); // 400,000 × 4.75%
      final tJuly = computeInsurance4(
        month: 7,
        taxableBaseWon: 300000,
        dailyTaxableWon: const [],
        workedDays: 8,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(tJuly.pensionWon, 19470); // 410,000 × 4.75% = 19,475 → 절사
      final t2 = computeInsurance4(
        month: 9,
        taxableBaseWon: 1234567,
        dailyTaxableWon: const [],
        workedDays: 8,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.exact,
      );
      expect(t2.pensionWon, 58615); // 1,234,000 × 4.75% = 58,615
    });
  });

  group('일용근로소득세', () {
    test('일당 200,000원: 소득세 1,350 + 지방소득세 130(절사) / 135(원단위)', () {
      final f = computeDailyIncomeTax(
        dailyTaxableWon: 200000,
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(f.incomeTaxWon, 1350);
      expect(f.localIncomeTaxWon, 130);
      final e = computeDailyIncomeTax(
        dailyTaxableWon: 200000,
        rates: rates,
        rounding: TaxRounding.exact,
      );
      expect(e.localIncomeTaxWon, 135);
    });

    test('일당 150,000원 이하는 세금 없음', () {
      expect(
        computeDailyIncomeTax(
          dailyTaxableWon: 150000,
          rates: rates,
          rounding: TaxRounding.floor10,
        ).isZero,
        true,
      );
      expect(
        computeDailyIncomeTax(
          dailyTaxableWon: 90000,
          rates: rates,
          rounding: TaxRounding.floor10,
        ).isZero,
        true,
      );
    });

    test('소액부징수: 하루 소득세 1,000원 미만이면 걷지 않는다', () {
      // 160,000 → 초과 10,000 × 6% = 600 × 45% = 270 → 0
      final t = computeDailyIncomeTax(
        dailyTaxableWon: 160000,
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(t.isZero, true);
      // 187,000 → 초과 37,000 × 6% = 2,220 − 세액공제 1,221 = 999 → 990 → 0
      expect(
        computeDailyIncomeTax(
          dailyTaxableWon: 187000,
          rates: rates,
          rounding: TaxRounding.floor10,
        ).isZero,
        true,
      );
      // 187,100 → 초과 37,100 × 6% = 2,226 − 세액공제 1,224 = 1,002 → 1,000 → 징수
      expect(
        computeDailyIncomeTax(
          dailyTaxableWon: 187100,
          rates: rates,
          rounding: TaxRounding.floor10,
        ).incomeTaxWon,
        1000,
      );
    });

    test('4대보험 방식에서 일자별 합산 + 옵션 끄기', () {
      final on = computeInsurance4(
        month: 9,
        taxableBaseWon: 600000,
        dailyTaxableWon: const [200000, 200000, 200000],
        workedDays: 3,
        options: const TaxOptions(),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(on.incomeTaxWon, 4050);
      expect(on.localIncomeTaxWon, 390);
      final off = computeInsurance4(
        month: 9,
        taxableBaseWon: 600000,
        dailyTaxableWon: const [200000, 200000, 200000],
        workedDays: 3,
        options: const TaxOptions(applyDailyIncomeTax: false),
        rates: rates,
        rounding: TaxRounding.floor10,
      );
      expect(off.incomeTaxWon, 0);
    });
  });

  group('computeTax 진입점', () {
    test('공제 없음 / 기준 0원이면 0', () {
      expect(
        computeTax(
          month: 9,
          mode: TaxMode.none,
          options: TaxOptions.defaults,
          rates: rates,
          rounding: TaxRounding.floor10,
          taxableBaseWon: 1000000,
          dailyTaxableWon: const [],
          workedDays: 10,
        ).isZero,
        true,
      );
      expect(
        computeTax(
          month: 9,
          mode: TaxMode.withholding33,
          options: TaxOptions.defaults,
          rates: rates,
          rounding: TaxRounding.floor10,
          taxableBaseWon: 0,
          dailyTaxableWon: const [],
          workedDays: 0,
        ).isZero,
        true,
      );
    });

    test('코드 ↔ enum 왕복, 모르는 코드는 안전한 기본값', () {
      for (final m in TaxMode.values) {
        expect(TaxMode.fromCode(m.code), m);
      }
      expect(TaxMode.fromCode('garbage'), TaxMode.none);
      expect(TaxMode.fromCode(null), TaxMode.none);
      expect(TaxRounding.fromCode(null), TaxRounding.floor10);
      expect(TaxRounding.fromCode('exact'), TaxRounding.exact);
    });
  });

  group('TaxOptions JSON', () {
    test('왕복', () {
      const o = TaxOptions(pensionHealthMinDays: 0, applyDailyIncomeTax: false);
      final back = TaxOptions.fromJsonString(o.toJsonString());
      expect(back.pensionHealthMinDays, 0);
      expect(back.applyDailyIncomeTax, false);
    });

    test('손상/누락은 기본값', () {
      expect(TaxOptions.fromJsonString(null).pensionHealthMinDays, 8);
      expect(TaxOptions.fromJsonString('not json').applyDailyIncomeTax, true);
      expect(
        TaxOptions.fromJsonString('{"pensionHealthMinDays": 99}')
            .pensionHealthMinDays,
        8,
      );
      expect(TaxOptions.fromJsonString('[1,2]').pensionHealthMinDays, 8);
    });
  });

  group('TaxRateTable', () {
    test('연도 폴백: 미래 연도는 최신 승계, 과거 연도는 가장 이른 테이블', () {
      final t2030 = defaultTaxRateTable(2030);
      expect(t2030.year, 2030);
      // 요율은 최신 테이블 승계, 국민연금 상·하한은 최신 7월 개정치가 연중 이어진다.
      expect(
        t2030.pensionEmployeePer100k,
        taxRateTable2026.pensionEmployeePer100k,
      );
      expect(
        t2030.pensionMonthlyCapWon,
        taxRateTable2026.pensionMonthlyCapFromJulyWon,
      );
      expect(t2030.pensionCapFor(3), 6590000);
      expect(t2030.pensionCapFor(9), 6590000);
      final t2024 = defaultTaxRateTable(2024);
      expect(t2024.sameValuesAs(taxRateTable2025), true);
      expect(defaultTaxRateTable(2025).pensionEmployeePer100k, 4500);
      expect(defaultTaxRateTable(2026).pensionEmployeePer100k, 4750);
    });

    test('JSON 병합: 알 수 없는 키·음수·문자열은 무시', () {
      final merged = taxRateTable2026.mergeJson({
        'pensionEmployeePer100k': 5000,
        'healthEmployeePer100k': -1,
        'employmentEmployeePer100k': '900',
        'unknown': 1,
      });
      expect(merged.pensionEmployeePer100k, 5000);
      expect(merged.healthEmployeePer100k, 3595);
      expect(merged.employmentEmployeePer100k, 900);
      expect(merged.year, 2026);
    });

    test('toJson/withValue 전 키 일관성', () {
      final json = taxRateTable2026.toJson();
      expect(json.length, TaxRateKey.values.length);
      var t = taxRateTable2026;
      for (final k in TaxRateKey.values) {
        t = t.withValue(k, 7);
        expect(t.valueOf(k), 7);
      }
    });
  });
}
