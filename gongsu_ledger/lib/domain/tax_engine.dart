/// 세금·보험 공제 계산 엔진 — 순수 정수 연산.
///
/// 세금 방식은 업체별로 고른다:
/// - 공제 없음
/// - 3.3% 원천징수 (사업소득): 소득세 3% + 지방소득세(소득세의 10%)
/// - 4대보험 (근로자 부담분): 고용보험 + [월 근무일 조건 충족 시] 국민연금·
///   건강보험·장기요양 + [옵션] 일용근로소득세(일당 15만원 초과분 6% × 45%)
///
/// 끝전은 기본 "10원 미만 절사"(원천징수 실무 관행, 사용자 확정 결정).
/// 어떤 단계에서도 double을 쓰지 않는다.
library;

import 'dart:convert';

import 'tax_rates.dart';

enum TaxMode {
  none('none', '공제 없음'),
  withholding33('withholding33', '3.3% 원천징수'),
  insurance4('insurance4', '4대보험');

  const TaxMode(this.code, this.label);

  final String code;
  final String label;

  static TaxMode fromCode(String? code) =>
      values.firstWhere((m) => m.code == code, orElse: () => none);
}

enum TaxRounding {
  floor10('floor10', '10원 미만 절사'),
  exact('exact', '원 단위 그대로');

  const TaxRounding(this.code, this.label);

  final String code;
  final String label;

  static TaxRounding fromCode(String? code) =>
      values.firstWhere((r) => r.code == code, orElse: () => floor10);
}

/// 4대보험 방식의 업체별 세부 옵션. DB에는 JSON 문자열로 저장한다.
class TaxOptions {
  const TaxOptions({
    this.pensionHealthMinDays = 8,
    this.applyDailyIncomeTax = true,
  });

  /// 국민연금·건강보험(장기요양 포함)을 적용하는 최소 월 근무일.
  /// 건설 일용직은 통상 "월 8일 이상"부터 가입 대상. 0이면 항상 적용.
  final int pensionHealthMinDays;

  /// 일용근로소득세(일당 공제액 초과분 × 6% × 45%)를 함께 계산할지.
  final bool applyDailyIncomeTax;

  static const TaxOptions defaults = TaxOptions();

  Map<String, Object?> toJson() => {
    'pensionHealthMinDays': pensionHealthMinDays,
    'applyDailyIncomeTax': applyDailyIncomeTax,
  };

  String toJsonString() => jsonEncode(toJson());

  /// 손상된 JSON은 기본값으로 — 계산이 멈추지 않는다.
  static TaxOptions fromJsonString(String? json) {
    if (json == null || json.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, Object?>) return defaults;
      final minDays = decoded['pensionHealthMinDays'];
      final apply = decoded['applyDailyIncomeTax'];
      return TaxOptions(
        pensionHealthMinDays: minDays is int && minDays >= 0 && minDays <= 31
            ? minDays
            : defaults.pensionHealthMinDays,
        applyDailyIncomeTax: apply is bool
            ? apply
            : defaults.applyDailyIncomeTax,
      );
    } on FormatException {
      return defaults;
    }
  }

  TaxOptions copyWith({int? pensionHealthMinDays, bool? applyDailyIncomeTax}) =>
      TaxOptions(
        pensionHealthMinDays: pensionHealthMinDays ?? this.pensionHealthMinDays,
        applyDailyIncomeTax: applyDailyIncomeTax ?? this.applyDailyIncomeTax,
      );
}

/// 공제 내역 (원). 전부 0 이상.
class TaxBreakdown {
  const TaxBreakdown({
    this.incomeTaxWon = 0,
    this.localIncomeTaxWon = 0,
    this.pensionWon = 0,
    this.healthWon = 0,
    this.longTermCareWon = 0,
    this.employmentWon = 0,
  });

  final int incomeTaxWon;
  final int localIncomeTaxWon;
  final int pensionWon;
  final int healthWon;
  final int longTermCareWon;
  final int employmentWon;

  int get totalWon =>
      incomeTaxWon +
      localIncomeTaxWon +
      pensionWon +
      healthWon +
      longTermCareWon +
      employmentWon;

  bool get isZero => totalWon == 0;

  static const zero = TaxBreakdown();

  TaxBreakdown operator +(TaxBreakdown o) => TaxBreakdown(
    incomeTaxWon: incomeTaxWon + o.incomeTaxWon,
    localIncomeTaxWon: localIncomeTaxWon + o.localIncomeTaxWon,
    pensionWon: pensionWon + o.pensionWon,
    healthWon: healthWon + o.healthWon,
    longTermCareWon: longTermCareWon + o.longTermCareWon,
    employmentWon: employmentWon + o.employmentWon,
  );
}

/// 십만분율 곱셈. 1원 미만 절사.
int percentOf(int amountWon, int per100k) {
  assert(amountWon >= 0 && per100k >= 0);
  return (amountWon * per100k) ~/ 100000;
}

int applyRounding(int won, TaxRounding rounding) => switch (rounding) {
  TaxRounding.floor10 => (won ~/ 10) * 10,
  TaxRounding.exact => won,
};

/// 3.3% 원천징수: 소득세 = 기준 × 3%, 지방소득세 = 소득세 × 10%.
TaxBreakdown computeWithholding33({
  required int taxableBaseWon,
  required TaxRateTable rates,
  required TaxRounding rounding,
}) {
  final incomeTax = applyRounding(
    percentOf(taxableBaseWon, rates.withholdingIncomeTaxPer100k),
    rounding,
  );
  final localTax = applyRounding(
    percentOf(incomeTax, rates.localTaxPer100kOfIncomeTax),
    rounding,
  );
  return TaxBreakdown(incomeTaxWon: incomeTax, localIncomeTaxWon: localTax);
}

/// 일용근로소득세 (하루 단위). 공제액 초과분 × 세율 − 세액공제, 소액부징수.
TaxBreakdown computeDailyIncomeTax({
  required int dailyTaxableWon,
  required TaxRateTable rates,
  required TaxRounding rounding,
}) {
  final excess = dailyTaxableWon - rates.dailyTaxExemptWon;
  if (excess <= 0) return TaxBreakdown.zero;
  final calculated = percentOf(excess, rates.dailyIncomeTaxPer100k);
  final credit = percentOf(calculated, rates.dailyTaxCreditPer100k);
  var payable = applyRounding(calculated - credit, rounding);
  if (payable < rates.dailyTaxMinWon) payable = 0;
  final local = payable == 0
      ? 0
      : applyRounding(
          percentOf(payable, rates.localTaxPer100kOfIncomeTax),
          rounding,
        );
  return TaxBreakdown(incomeTaxWon: payable, localIncomeTaxWon: local);
}

/// 4대보험 근로자 부담분 (+ 옵션: 일용근로소득세).
///
/// [taxableBaseWon]: 기간(통상 한 달)의 과세 기준 — 노무비 + 과세 가산항목.
/// [dailyTaxableWon]: 날짜별 과세 기준 목록 (일용근로소득세용).
/// [workedDays]: 이 업체에서 공수 > 0인 날 수 — 연금·건강 적용 조건 판정.
TaxBreakdown computeInsurance4({
  required int taxableBaseWon,
  required Iterable<int> dailyTaxableWon,
  required int workedDays,
  required TaxOptions options,
  required TaxRateTable rates,
  required TaxRounding rounding,
}) {
  assert(taxableBaseWon >= 0);
  final employment = applyRounding(
    percentOf(taxableBaseWon, rates.employmentEmployeePer100k),
    rounding,
  );

  var pension = 0;
  var health = 0;
  var longTermCare = 0;
  if (workedDays >= options.pensionHealthMinDays) {
    // 기준소득월액: 상·하한으로 자르고 천원 미만 절사.
    var base = taxableBaseWon;
    if (base > rates.pensionMonthlyCapWon) base = rates.pensionMonthlyCapWon;
    if (base < rates.pensionMonthlyFloorWon) {
      base = rates.pensionMonthlyFloorWon;
    }
    base = (base ~/ 1000) * 1000;
    pension = applyRounding(
      percentOf(base, rates.pensionEmployeePer100k),
      rounding,
    );
    health = applyRounding(
      percentOf(taxableBaseWon, rates.healthEmployeePer100k),
      rounding,
    );
    longTermCare = applyRounding(
      percentOf(health, rates.longTermCarePer100kOfHealth),
      rounding,
    );
  }

  var daily = TaxBreakdown.zero;
  if (options.applyDailyIncomeTax) {
    for (final d in dailyTaxableWon) {
      daily =
          daily +
          computeDailyIncomeTax(
            dailyTaxableWon: d,
            rates: rates,
            rounding: rounding,
          );
    }
  }

  return TaxBreakdown(
    incomeTaxWon: daily.incomeTaxWon,
    localIncomeTaxWon: daily.localIncomeTaxWon,
    pensionWon: pension,
    healthWon: health,
    longTermCareWon: longTermCare,
    employmentWon: employment,
  );
}

/// 업체 세금 방식에 따른 공제 계산 진입점.
TaxBreakdown computeTax({
  required TaxMode mode,
  required TaxOptions options,
  required TaxRateTable rates,
  required TaxRounding rounding,
  required int taxableBaseWon,
  required Iterable<int> dailyTaxableWon,
  required int workedDays,
}) {
  if (taxableBaseWon <= 0) return TaxBreakdown.zero;
  return switch (mode) {
    TaxMode.none => TaxBreakdown.zero,
    TaxMode.withholding33 => computeWithholding33(
      taxableBaseWon: taxableBaseWon,
      rates: rates,
      rounding: rounding,
    ),
    TaxMode.insurance4 => computeInsurance4(
      taxableBaseWon: taxableBaseWon,
      dailyTaxableWon: dailyTaxableWon,
      workedDays: workedDays,
      options: options,
      rates: rates,
      rounding: rounding,
    ),
  };
}
