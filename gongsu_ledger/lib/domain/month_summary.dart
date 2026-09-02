/// 월 합계 모델과 합산 순수 함수.
///
/// 합산은 centi-공수 int로 끝까지 수행하고 포맷은 마지막에 1회만 한다.
/// 금액 필드는 M2(단가)·M3(세금)에서 채워지도록 nullable로 지금 고정해
/// 달력/합계 카드의 UI 계약이 이후 마일스톤에서 바뀌지 않게 한다.
library;

class MonthSummary {
  const MonthSummary({
    required this.totalCenti,
    required this.workedDays,
    required this.entryCount,
    this.grossWon,
    this.netWon,
  });

  /// 월 총 공수 (centi).
  final int totalCenti;

  /// 공수가 0보다 큰 기록이 하나라도 있는 날의 수. 휴무(0)만 있는 날은 제외.
  final int workedDays;

  /// 살아있는 기록 건수 (휴무 포함).
  final int entryCount;

  /// 세전 수입(원). M2 단가 도입 전에는 null.
  final int? grossWon;

  /// 세후 실수령(원). M3 세금 도입 전에는 null.
  final int? netWon;

  static const empty = MonthSummary(
    totalCenti: 0,
    workedDays: 0,
    entryCount: 0,
  );

  MonthSummary withMoney({required int? grossWon, required int? netWon}) =>
      MonthSummary(
        totalCenti: totalCenti,
        workedDays: workedDays,
        entryCount: entryCount,
        grossWon: grossWon,
        netWon: netWon,
      );
}

/// dateKey → 그 날의 centi-공수 목록에서 월 합계를 만든다.
MonthSummary buildMonthSummary(Map<int, List<int>> centiByDay) {
  var total = 0;
  var workedDays = 0;
  var entryCount = 0;
  for (final centis in centiByDay.values) {
    var dayTotal = 0;
    for (final c in centis) {
      assert(c >= 0, '공수는 음수가 될 수 없다');
      dayTotal += c;
      entryCount++;
    }
    total += dayTotal;
    if (dayTotal > 0) workedDays++;
  }
  return MonthSummary(
    totalCenti: total,
    workedDays: workedDays,
    entryCount: entryCount,
  );
}
