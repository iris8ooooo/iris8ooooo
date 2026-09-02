/// 월 금액 집계 — 순수 정수 연산.
///
/// 세전 예상 수입 = 공수×단가 합(labor) + 가산 항목 합 − 공제 항목 합.
/// 세후(netWon)는 M3 세금 정산에서 채운다.
library;

import 'gongsu_value.dart';
import 'rate_resolver.dart';

typedef EntryForMoney = ({
  int dateKey,
  int centiGongsu,
  int? siteId,
  int? unitRateWonOverride,
});

typedef ExtraItemForMoney = ({bool isDeduction, int amountWon});

class MonthMoney {
  const MonthMoney({
    required this.laborWon,
    required this.allowanceWon,
    required this.deductionWon,
    required this.pricedEntryCount,
    required this.unpricedCenti,
    required this.itemCount,
  });

  /// 공수 × 단가 합 (원). 단가가 해석된 기록만.
  final int laborWon;

  /// 가산 항목(일비/식비/숙식비 등) 합.
  final int allowanceWon;

  /// 공제 항목(안전용품비 등) 합.
  final int deductionWon;

  /// 단가가 해석된 기록 수.
  final int pricedEntryCount;

  /// 단가 미설정이라 금액에 못 넣은 공수 (사용자에게 "단가 미설정 N공수" 안내용).
  final int unpricedCenti;

  final int itemCount;

  /// 세전 예상 수입.
  int get grossWon => laborWon + allowanceWon - deductionWon;

  /// 업체/단가/부가항목을 하나도 안 쓰는 사용자에게 "0원"을 보여주지 않기 위한
  /// 판정 — 금액 정보가 하나라도 있을 때만 의미가 있다.
  bool get isMeaningful => pricedEntryCount > 0 || itemCount > 0;

  static const empty = MonthMoney(
    laborWon: 0,
    allowanceWon: 0,
    deductionWon: 0,
    pricedEntryCount: 0,
    unpricedCenti: 0,
    itemCount: 0,
  );
}

MonthMoney buildMonthMoney({
  required Iterable<EntryForMoney> entries,
  required Iterable<RateHistoryEntry> histories,
  required Iterable<ExtraItemForMoney> items,
}) {
  var labor = 0;
  var priced = 0;
  var unpriced = 0;
  for (final e in entries) {
    assert(e.centiGongsu >= 0);
    final rate = resolveEntryRateWon(
      dateKey: e.dateKey,
      siteId: e.siteId,
      unitRateWonOverride: e.unitRateWonOverride,
      histories: histories,
    );
    if (rate == null) {
      unpriced += e.centiGongsu;
      continue;
    }
    labor += calcAmountWon(centiGongsu: e.centiGongsu, dailyRateWon: rate);
    priced++;
  }

  var allowance = 0;
  var deduction = 0;
  var itemCount = 0;
  for (final it in items) {
    assert(it.amountWon >= 0, '부가항목 금액은 0 이상, 방향은 kind로 정한다');
    if (it.isDeduction) {
      deduction += it.amountWon;
    } else {
      allowance += it.amountWon;
    }
    itemCount++;
  }

  return MonthMoney(
    laborWon: labor,
    allowanceWon: allowance,
    deductionWon: deduction,
    pricedEntryCount: priced,
    unpricedCenti: unpriced,
    itemCount: itemCount,
  );
}
