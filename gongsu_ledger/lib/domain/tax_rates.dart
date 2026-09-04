/// 세율·보험료율 테이블 — 연도별 상수 + 사용자 오버라이드(JSON 병합).
///
/// 모든 비율은 십만분율(per100k) 정수: 4.75% = 4750. double 금지.
/// 근로자 부담분만 다룬다 — 사업주 부담분과 산재보험은 실수령과 무관하다.
///
/// 경쟁앱 불만("2026년 세율 변경 반영해달라")에 대응해 연도별 테이블을
/// 두고, 갱신이 늦어져도 사용자가 직접 고칠 수 있게 모든 값을 열어 둔다.
library;

/// 요율 항목 종류 — 설정 화면이 이 목록으로 입력칸을 그린다.
enum TaxRateFieldKind { percent, won }

enum TaxRateKey {
  pensionEmployee(
    'pensionEmployeePer100k',
    '국민연금 (근로자 부담)',
    TaxRateFieldKind.percent,
    '월 소득 기준. 2026년 4.75% (전체 9.5%)',
  ),
  healthEmployee(
    'healthEmployeePer100k',
    '건강보험 (근로자 부담)',
    TaxRateFieldKind.percent,
    '월 소득 기준. 2026년 3.595% (전체 7.19%)',
  ),
  longTermCareOfHealth(
    'longTermCarePer100kOfHealth',
    '장기요양보험 (건강보험료의 %)',
    TaxRateFieldKind.percent,
    '건강보험료에 곱한다. 2026년 12.95%',
  ),
  employmentEmployee(
    'employmentEmployeePer100k',
    '고용보험 (근로자 부담)',
    TaxRateFieldKind.percent,
    '실업급여분 0.9%',
  ),
  pensionMonthlyCap(
    'pensionMonthlyCapWon',
    '국민연금 기준소득 상한 (월)',
    TaxRateFieldKind.won,
    '이 금액을 넘는 월 소득에는 연금이 더 붙지 않는다',
  ),
  pensionMonthlyFloor(
    'pensionMonthlyFloorWon',
    '국민연금 기준소득 하한 (월)',
    TaxRateFieldKind.won,
    '이보다 적어도 이 금액 기준으로 계산',
  ),
  pensionMonthlyCapFromJuly(
    'pensionMonthlyCapFromJulyWon',
    '국민연금 기준소득 상한 (7월부터)',
    TaxRateFieldKind.won,
    '상·하한은 매년 7월 1일에 바뀐다. 7~12월 정산에 이 값을 쓴다',
  ),
  pensionMonthlyFloorFromJuly(
    'pensionMonthlyFloorFromJulyWon',
    '국민연금 기준소득 하한 (7월부터)',
    TaxRateFieldKind.won,
    '7~12월 정산에 쓰는 하한',
  ),
  dailyTaxExempt(
    'dailyTaxExemptWon',
    '일용근로소득 일 공제액',
    TaxRateFieldKind.won,
    '일당에서 이 금액을 뺀 나머지에 세금',
  ),
  dailyIncomeTax(
    'dailyIncomeTaxPer100k',
    '일용근로소득 세율',
    TaxRateFieldKind.percent,
    '공제 후 금액의 6%',
  ),
  dailyTaxCredit(
    'dailyTaxCreditPer100k',
    '일용근로소득 세액공제',
    TaxRateFieldKind.percent,
    '산출세액의 55%를 빼 준다 (실효 2.7%)',
  ),
  dailyTaxMin(
    'dailyTaxMinWon',
    '소액부징수 기준',
    TaxRateFieldKind.won,
    '하루 소득세가 이 금액 미만이면 걷지 않는다',
  ),
  localTaxOfIncomeTax(
    'localTaxPer100kOfIncomeTax',
    '지방소득세 (소득세의 %)',
    TaxRateFieldKind.percent,
    '소득세에 곱한다. 10%',
  ),
  withholdingIncomeTax(
    'withholdingIncomeTaxPer100k',
    '3.3% 원천징수 중 소득세',
    TaxRateFieldKind.percent,
    '3% (지방소득세 0.3%는 위 지방소득세 비율로 계산)',
  );

  const TaxRateKey(this.code, this.label, this.kind, this.description);

  final String code;
  final String label;
  final TaxRateFieldKind kind;
  final String description;
}

class TaxRateTable {
  const TaxRateTable({
    required this.year,
    required this.pensionEmployeePer100k,
    required this.healthEmployeePer100k,
    required this.longTermCarePer100kOfHealth,
    required this.employmentEmployeePer100k,
    required this.pensionMonthlyCapWon,
    required this.pensionMonthlyFloorWon,
    required this.pensionMonthlyCapFromJulyWon,
    required this.pensionMonthlyFloorFromJulyWon,
    required this.dailyTaxExemptWon,
    required this.dailyIncomeTaxPer100k,
    required this.dailyTaxCreditPer100k,
    required this.dailyTaxMinWon,
    required this.localTaxPer100kOfIncomeTax,
    required this.withholdingIncomeTaxPer100k,
  });

  final int year;
  final int pensionEmployeePer100k;
  final int healthEmployeePer100k;
  final int longTermCarePer100kOfHealth;
  final int employmentEmployeePer100k;

  /// 1~6월에 적용되는 기준소득월액 상·하한 (전년 7월 개정치).
  final int pensionMonthlyCapWon;
  final int pensionMonthlyFloorWon;

  /// 7~12월에 적용되는 상·하한 (그해 7월 개정치). 개정은 매년 7월 1일.
  final int pensionMonthlyCapFromJulyWon;
  final int pensionMonthlyFloorFromJulyWon;
  final int dailyTaxExemptWon;

  /// 정산 대상 월(1~12)의 기준소득월액 상한.
  int pensionCapFor(int month) =>
      month >= 7 ? pensionMonthlyCapFromJulyWon : pensionMonthlyCapWon;

  int pensionFloorFor(int month) =>
      month >= 7 ? pensionMonthlyFloorFromJulyWon : pensionMonthlyFloorWon;
  final int dailyIncomeTaxPer100k;
  final int dailyTaxCreditPer100k;
  final int dailyTaxMinWon;
  final int localTaxPer100kOfIncomeTax;
  final int withholdingIncomeTaxPer100k;

  int valueOf(TaxRateKey key) => switch (key) {
    TaxRateKey.pensionEmployee => pensionEmployeePer100k,
    TaxRateKey.healthEmployee => healthEmployeePer100k,
    TaxRateKey.longTermCareOfHealth => longTermCarePer100kOfHealth,
    TaxRateKey.employmentEmployee => employmentEmployeePer100k,
    TaxRateKey.pensionMonthlyCap => pensionMonthlyCapWon,
    TaxRateKey.pensionMonthlyFloor => pensionMonthlyFloorWon,
    TaxRateKey.pensionMonthlyCapFromJuly => pensionMonthlyCapFromJulyWon,
    TaxRateKey.pensionMonthlyFloorFromJuly => pensionMonthlyFloorFromJulyWon,
    TaxRateKey.dailyTaxExempt => dailyTaxExemptWon,
    TaxRateKey.dailyIncomeTax => dailyIncomeTaxPer100k,
    TaxRateKey.dailyTaxCredit => dailyTaxCreditPer100k,
    TaxRateKey.dailyTaxMin => dailyTaxMinWon,
    TaxRateKey.localTaxOfIncomeTax => localTaxPer100kOfIncomeTax,
    TaxRateKey.withholdingIncomeTax => withholdingIncomeTaxPer100k,
  };

  TaxRateTable withValue(TaxRateKey key, int value) {
    assert(value >= 0);
    return TaxRateTable(
      year: year,
      pensionEmployeePer100k: key == TaxRateKey.pensionEmployee
          ? value
          : pensionEmployeePer100k,
      healthEmployeePer100k: key == TaxRateKey.healthEmployee
          ? value
          : healthEmployeePer100k,
      longTermCarePer100kOfHealth: key == TaxRateKey.longTermCareOfHealth
          ? value
          : longTermCarePer100kOfHealth,
      employmentEmployeePer100k: key == TaxRateKey.employmentEmployee
          ? value
          : employmentEmployeePer100k,
      pensionMonthlyCapWon: key == TaxRateKey.pensionMonthlyCap
          ? value
          : pensionMonthlyCapWon,
      pensionMonthlyFloorWon: key == TaxRateKey.pensionMonthlyFloor
          ? value
          : pensionMonthlyFloorWon,
      pensionMonthlyCapFromJulyWon: key == TaxRateKey.pensionMonthlyCapFromJuly
          ? value
          : pensionMonthlyCapFromJulyWon,
      pensionMonthlyFloorFromJulyWon:
          key == TaxRateKey.pensionMonthlyFloorFromJuly
          ? value
          : pensionMonthlyFloorFromJulyWon,
      dailyTaxExemptWon: key == TaxRateKey.dailyTaxExempt
          ? value
          : dailyTaxExemptWon,
      dailyIncomeTaxPer100k: key == TaxRateKey.dailyIncomeTax
          ? value
          : dailyIncomeTaxPer100k,
      dailyTaxCreditPer100k: key == TaxRateKey.dailyTaxCredit
          ? value
          : dailyTaxCreditPer100k,
      dailyTaxMinWon: key == TaxRateKey.dailyTaxMin ? value : dailyTaxMinWon,
      localTaxPer100kOfIncomeTax: key == TaxRateKey.localTaxOfIncomeTax
          ? value
          : localTaxPer100kOfIncomeTax,
      withholdingIncomeTaxPer100k: key == TaxRateKey.withholdingIncomeTax
          ? value
          : withholdingIncomeTaxPer100k,
    );
  }

  /// 설정 저장용. 키는 [TaxRateKey.code].
  Map<String, int> toJson() => {
    for (final k in TaxRateKey.values) k.code: valueOf(k),
  };

  /// 사용자 오버라이드 병합. 모르는 키·음수·정수가 아닌 값은 무시한다
  /// (forward-tolerant — 손상된 설정이 계산을 깨뜨리지 않는다).
  TaxRateTable mergeJson(Map<String, Object?> json) {
    var table = this;
    for (final k in TaxRateKey.values) {
      final v = json[k.code];
      if (v is int && v >= 0 && v <= 1000000000000) {
        table = table.withValue(k, v);
      }
    }
    return table;
  }

  bool sameValuesAs(TaxRateTable other) =>
      TaxRateKey.values.every((k) => valueOf(k) == other.valueOf(k));
}

/// 2025년 근로자 부담 요율.
/// - 국민연금 4.5% (전체 9%), 건강보험 3.545% (전체 7.09%), 장기요양 12.95%
/// - 고용보험 0.9%, 기준소득월액 상한/하한: 1~6월 6,170,000/390,000 (2024.7 개정),
///   7~12월 6,370,000/400,000 (2025.7 개정)
/// - 일용근로소득: 일 15만원 공제, 6%, 세액공제 55%, 소액부징수 1,000원
const TaxRateTable taxRateTable2025 = TaxRateTable(
  year: 2025,
  pensionEmployeePer100k: 4500,
  healthEmployeePer100k: 3545,
  longTermCarePer100kOfHealth: 12950,
  employmentEmployeePer100k: 900,
  pensionMonthlyCapWon: 6170000,
  pensionMonthlyFloorWon: 390000,
  pensionMonthlyCapFromJulyWon: 6370000,
  pensionMonthlyFloorFromJulyWon: 400000,
  dailyTaxExemptWon: 150000,
  dailyIncomeTaxPer100k: 6000,
  dailyTaxCreditPer100k: 55000,
  dailyTaxMinWon: 1000,
  localTaxPer100kOfIncomeTax: 10000,
  withholdingIncomeTaxPer100k: 3000,
);

/// 2026년 근로자 부담 요율.
/// - 국민연금 4.75% (전체 9.5% — 2026년부터 매년 0.5%p 인상, 2033년 13%)
/// - 건강보험 3.595% (전체 7.19%), 장기요양 12.95% (동결)
/// - 고용보험 0.9%, 기준소득월액 상한/하한: 1~6월 6,370,000/400,000 (2025.7 개정),
///   7~12월 6,590,000/410,000 (2026.7 개정, A값 변동률 3.4% 반영 — 국민연금공단 안내)
const TaxRateTable taxRateTable2026 = TaxRateTable(
  year: 2026,
  pensionEmployeePer100k: 4750,
  healthEmployeePer100k: 3595,
  longTermCarePer100kOfHealth: 12950,
  employmentEmployeePer100k: 900,
  pensionMonthlyCapWon: 6370000,
  pensionMonthlyFloorWon: 400000,
  pensionMonthlyCapFromJulyWon: 6590000,
  pensionMonthlyFloorFromJulyWon: 410000,
  dailyTaxExemptWon: 150000,
  dailyIncomeTaxPer100k: 6000,
  dailyTaxCreditPer100k: 55000,
  dailyTaxMinWon: 1000,
  localTaxPer100kOfIncomeTax: 10000,
  withholdingIncomeTaxPer100k: 3000,
);

const Map<int, TaxRateTable> defaultTaxRateTables = {
  2025: taxRateTable2025,
  2026: taxRateTable2026,
};

/// 연도의 기본 테이블. 정확한 연도가 없으면 그 이전의 가장 최근 연도,
/// 그것도 없으면 가장 이른 연도를 쓴다 (미래 연도는 최신 요율 승계).
TaxRateTable defaultTaxRateTable(int year) {
  final exact = defaultTaxRateTables[year];
  if (exact != null) return exact;
  final years = defaultTaxRateTables.keys.toList()..sort();
  int? best;
  for (final y in years) {
    if (y <= year) best = y;
  }
  final chosen = best ?? years.first;
  final base = defaultTaxRateTables[chosen]!;
  // 미래 연도 승계: 최신 테이블의 7월 개정치가 그 다음 해 1~6월에도 이어진다.
  // 과거 연도(가장 이른 테이블보다 앞)는 그 테이블 값을 그대로 쓴다.
  final carryJuly = best != null;
  return TaxRateTable(
    year: year,
    pensionEmployeePer100k: base.pensionEmployeePer100k,
    healthEmployeePer100k: base.healthEmployeePer100k,
    longTermCarePer100kOfHealth: base.longTermCarePer100kOfHealth,
    employmentEmployeePer100k: base.employmentEmployeePer100k,
    pensionMonthlyCapWon: carryJuly
        ? base.pensionMonthlyCapFromJulyWon
        : base.pensionMonthlyCapWon,
    pensionMonthlyFloorWon: carryJuly
        ? base.pensionMonthlyFloorFromJulyWon
        : base.pensionMonthlyFloorWon,
    pensionMonthlyCapFromJulyWon: base.pensionMonthlyCapFromJulyWon,
    pensionMonthlyFloorFromJulyWon: base.pensionMonthlyFloorFromJulyWon,
    dailyTaxExemptWon: base.dailyTaxExemptWon,
    dailyIncomeTaxPer100k: base.dailyIncomeTaxPer100k,
    dailyTaxCreditPer100k: base.dailyTaxCreditPer100k,
    dailyTaxMinWon: base.dailyTaxMinWon,
    localTaxPer100kOfIncomeTax: base.localTaxPer100kOfIncomeTax,
    withholdingIncomeTaxPer100k: base.withholdingIncomeTaxPer100k,
  );
}
