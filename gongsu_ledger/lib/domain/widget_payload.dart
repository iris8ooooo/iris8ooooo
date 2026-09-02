import 'gongsu_value.dart';
import 'month_grid.dart';
import 'settlement.dart';

/// 홈 위젯에 넘기는 키. iOS(GongsuWidget.swift)·Android(GongsuWidgetProvider.kt)가
/// 같은 문자열로 읽으므로 이름을 바꾸면 세 곳을 함께 고쳐야 한다.
///
/// 값은 전부 "표시용 문자열"이다 — 위젯 쪽은 계산하지 않고 그대로 보여준다
/// (숫자 정확성·반올림 금지 원칙을 앱 한 곳에서만 책임지기 위해).
class WidgetKeys {
  WidgetKeys._();

  /// "9월"
  static const String monthLabel = 'widget_month_label';

  /// "30.8" (후행 0 제거, 반올림 없음)
  static const String gongsu = 'widget_gongsu';

  /// "24"
  static const String workedDays = 'widget_worked_days';

  /// "실수령" | "세전" | "" (금액 정보 없음)
  static const String moneyLabel = 'widget_money_label';

  /// "5,318,090원" | "" (금액 정보 없음)
  static const String money = 'widget_money';

  /// "9/2 14:30" — 앱이 마지막으로 값을 보낸 시각
  static const String updatedAt = 'widget_updated_at';

  /// "1" 이면 프로가 아니라 잠김 — 위젯은 숫자 대신 안내 문구를 보여준다
  static const String locked = 'widget_locked';

  static const List<String> all = [
    monthLabel,
    gongsu,
    workedDays,
    moneyLabel,
    money,
    updatedAt,
    locked,
  ];
}

/// 프로가 아닐 때의 페이로드 — 숫자 없이 잠김 표식만.
Map<String, String> buildLockedWidgetPayload({
  required int ym,
  required DateTime now,
}) => {
  WidgetKeys.monthLabel: '${monthOfYm(ym)}월',
  WidgetKeys.gongsu: '',
  WidgetKeys.workedDays: '',
  WidgetKeys.moneyLabel: '',
  WidgetKeys.money: '',
  WidgetKeys.updatedAt: _stamp(now),
  WidgetKeys.locked: '1',
};

/// 달의 정산 결과 → 위젯 표시 문자열 묶음. 순수 함수.
///
/// 금액 줄: 세금 방식이 설정된 업체가 하나라도 있으면 실수령(세후), 아니면 세전.
/// 단가·부가항목으로 생긴 실제 금액이 없으면(단가 없는 공수뿐이면) 금액 줄은
/// 비운다 — 월 카드가 금액 줄을 숨기는 것과 같은 규칙.
Map<String, String> buildWidgetPayload({
  required int ym,
  required PeriodSettlement settlement,
  required DateTime now,
}) {
  final hasMoney = hasPricedMoney(settlement);
  final afterTax = settlement.hasTaxConfigured;
  final won = afterTax ? settlement.netWon : settlement.grossWon;
  return {
    WidgetKeys.monthLabel: '${monthOfYm(ym)}월',
    WidgetKeys.gongsu: formatGongsu(settlement.totalCenti),
    WidgetKeys.workedDays: '${settlement.workedDays}',
    WidgetKeys.moneyLabel: !hasMoney ? '' : (afterTax ? '실수령' : '세전'),
    WidgetKeys.money: !hasMoney ? '' : '${groupDigits(won)}원',
    WidgetKeys.updatedAt: _stamp(now),
    WidgetKeys.locked: '0',
  };
}

String _stamp(DateTime now) =>
    '${now.month}/${now.day} ${_two(now.hour)}:${_two(now.minute)}';

/// 노무비(공수×단가)·가산·공제 중 하나라도 실제 금액이 있는가.
/// (PeriodSettlement.hasMoney 는 정산 화면용으로 '단가 없는 공수'도 포함한다)
bool hasPricedMoney(PeriodSettlement settlement) => settlement.sites.any(
  (s) => s.laborWon > 0 || s.allowanceWon > 0 || s.deductionWon > 0,
);

/// 1234000 → "1,234,000". 음수는 "-" 뒤에 같은 규칙. intl 없이 정수만 다룬다.
String groupDigits(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _two(int v) => v.toString().padLeft(2, '0');
