/// 월 달력 격자 산출. 순수 함수 — 여기서 계산된 dateKey가 달력 셀의
/// 정체성이며, 탭 → 저장 경로에 DateTime 변환이 다시 등장하지 않는다.
/// ("매월 1일 입력 불가" 계열 버그를 구조적으로 차단하는 지점)
library;

import 'date_key.dart';

/// 연·월 키 (yyyyMM 정수). 202608 = 2026년 8월.
int ymOf(int year, int month) => year * 100 + month;

int ymOfDateKey(int dateKey) => dateKey ~/ 100;

int yearOfYm(int ym) => ym ~/ 100;

int monthOfYm(int ym) => ym % 100;

int nextYm(int ym) {
  final m = monthOfYm(ym);
  return m == 12 ? ymOf(yearOfYm(ym) + 1, 1) : ym + 1;
}

int prevYm(int ym) {
  final m = monthOfYm(ym);
  return m == 1 ? ymOf(yearOfYm(ym) - 1, 12) : ym - 1;
}

/// 두 yyyyMM 키 사이의 개월 수 차이 (a - b).
int ymDiff(int a, int b) =>
    (yearOfYm(a) - yearOfYm(b)) * 12 + (monthOfYm(a) - monthOfYm(b));

/// ym에 개월 수를 더한다.
int ymAddMonths(int ym, int months) {
  final total = yearOfYm(ym) * 12 + (monthOfYm(ym) - 1) + months;
  return ymOf(total ~/ 12, total % 12 + 1);
}

/// 해당 월의 일수.
int daysInMonth(int ym) =>
    DateTime(yearOfYm(ym), monthOfYm(ym) + 1, 0).day;

/// 고정 6주(42칸) 월 격자의 dateKey 목록을 만든다.
///
/// [weekStartWeekday]는 DateTime.weekday 규약(월=1 … 일=7). 기본 일요일.
/// 첫 칸은 해당 월 1일이 포함된 주의 시작 요일이고, 이후 42일 연속이다.
/// 고정 42칸이라 월마다 달력 높이가 출렁이지 않는다.
List<int> monthGridDateKeys(int ym, {int weekStartWeekday = DateTime.sunday}) {
  final year = yearOfYm(ym);
  final month = monthOfYm(ym);
  final firstWeekday = DateTime(year, month, 1).weekday; // 월=1 … 일=7
  final offset = (firstWeekday - weekStartWeekday) % 7;
  // DateTime(y, m, d)는 d가 0 이하·말일 초과여도 정규화하므로 (로컬 기준,
  // UTC 미사용) 월/연 경계를 안전하게 넘는다.
  return List<int>.generate(
    42,
    (i) => dateKeyOf(DateTime(year, month, 1 - offset + i)),
  );
}

/// 격자 헤더용 요일 순서 (DateTime.weekday 값 7개).
List<int> weekdayOrder({int weekStartWeekday = DateTime.sunday}) =>
    List<int>.generate(7, (i) => (weekStartWeekday - 1 + i) % 7 + 1);
