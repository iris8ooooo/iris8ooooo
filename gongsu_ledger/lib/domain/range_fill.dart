/// 연속 채우기 — 시작~종료일에 같은 공수/업체를 한 번에 넣을 날짜를 고른다.
/// 순수 함수: 이미 기록이 있는 날은 건너뛰고(두 번 기록 방지), 옵션으로
/// 일요일·공휴일도 건너뛴다.
library;

import 'date_key.dart';
import 'korean_holidays.dart';

typedef RangeFillPlan = ({
  List<int> dateKeys,
  int skippedOccupied,
  int skippedRest,
});

/// 한 번에 채울 수 있는 최대 일수 (오타로 1년치를 넣는 사고 방지).
const int maxRangeFillDays = 62;

/// 일요일이거나 공휴일이면 쉬는 날.
bool isRestDay(int dateKey) =>
    dateFromKey(dateKey).weekday == DateTime.sunday || isKoreanHoliday(dateKey);

/// [fromKey]~[toKey](양끝 포함) 중 채울 날짜. [occupied]는 이미 기록이 있는
/// 날짜 키. [toKey] < [fromKey] 이면 빈 계획.
RangeFillPlan planRangeFill({
  required int fromKey,
  required int toKey,
  required bool skipRestDays,
  required Set<int> occupied,
}) {
  final keys = <int>[];
  var skippedOccupied = 0;
  var skippedRest = 0;
  var d = dateFromKey(fromKey);
  final end = dateFromKey(toKey);
  var count = 0;
  while (!d.isAfter(end) && count < maxRangeFillDays) {
    count++;
    final key = dateKeyOf(d);
    d = DateTime(d.year, d.month, d.day + 1);
    if (occupied.contains(key)) {
      skippedOccupied++;
      continue;
    }
    if (skipRestDays && isRestDay(key)) {
      skippedRest++;
      continue;
    }
    keys.add(key);
  }
  return (
    dateKeys: keys,
    skippedOccupied: skippedOccupied,
    skippedRest: skippedRest,
  );
}

/// [dateKey]가 속한 달의 말일 키.
int monthEndKeyOf(int dateKey) {
  final d = dateFromKey(dateKey);
  return dateKeyOf(DateTime(d.year, d.month + 1, 0));
}

/// [dateKey]에서 [days]일 뒤 키.
int addDaysToKey(int dateKey, int days) {
  final d = dateFromKey(dateKey);
  return dateKeyOf(DateTime(d.year, d.month, d.day + days));
}
