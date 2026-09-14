import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/korean_holidays.dart';

void main() {
  test('2026년 주요 공휴일', () {
    expect(koreanHolidayName(20260101), '신정');
    expect(koreanHolidayName(20260217), '설날');
    expect(koreanHolidayName(20260302), '대체공휴일'); // 삼일절이 일요일
    expect(koreanHolidayName(20260525), '대체공휴일'); // 부처님오신날이 일요일
    expect(koreanHolidayName(20260603), '지방선거');
    expect(koreanHolidayName(20260817), '대체공휴일'); // 광복절이 토요일
    expect(koreanHolidayName(20260925), '추석');
    expect(koreanHolidayName(20261009), '한글날');
    expect(koreanHolidayName(20261225), '성탄절');
  });

  test('2025년: 추석 대체공휴일·대선', () {
    expect(koreanHolidayName(20251006), '추석');
    expect(koreanHolidayName(20251008), '대체공휴일');
    expect(koreanHolidayName(20250603), '대통령선거');
    expect(koreanHolidayName(20250506), '대체공휴일');
  });

  test('평일은 null, 토요일도 공휴일 아님', () {
    expect(koreanHolidayName(20260102), null);
    expect(isKoreanHoliday(20260606), true); // 현충일(토)
    expect(isKoreanHoliday(20260613), false); // 평범한 토요일
    expect(isKoreanHoliday(20241225), false); // 데이터 없는 연도
  });

  test('내장 연도', () {
    expect(koreanHolidayYears, containsAll([2025, 2026, 2027]));
  });

  test('칸에 넣는 짧은 이름 (4자 이내)', () {
    expect(holidayShortName('대체공휴일'), '대체휴일');
    expect(holidayShortName('임시공휴일'), '임시휴일');
    expect(holidayShortName('부처님오신날'), '석탄일');
    expect(holidayShortName('어린이날·부처님오신날'), '어린이날');
    expect(holidayShortName('대통령선거'), '선거일');
    expect(holidayShortName('지방선거'), '선거일');
    expect(holidayShortName('설날 연휴'), '설날');
    expect(holidayShortName('추석 연휴'), '추석');
    expect(holidayShortName('한글날'), '한글날');
    for (final name in {
      for (var k = 20250101; k <= 20271231; k++) koreanHolidayName(k),
    }.nonNulls) {
      expect(holidayShortName(name).length, lessThanOrEqualTo(4), reason: name);
    }
  });

  test('한 달 공휴일 목록: 날짜 오름차순, 짧은 이름', () {
    expect(holidaysInMonth(202609), {
      20260924: '추석',
      20260925: '추석',
      20260926: '추석',
      20260928: '대체휴일',
    });
    expect(holidaysInMonth(202604), isEmpty);
    expect(holidaysInMonth(202801), isEmpty); // 데이터 없는 연도
  });

  test('달력 위 요약: 연속된 같은 이름은 범위로', () {
    expect(holidaySummary(202609), '추석 24~26 · 대체휴일 28');
    expect(holidaySummary(202602), '설날 16~18');
    expect(holidaySummary(202505), '어린이날 5 · 대체휴일 6');
    expect(holidaySummary(202702), '설날 5~7 · 대체휴일 8~9');
    expect(holidaySummary(202610), '개천절 3 · 대체휴일 5 · 한글날 9');
    expect(holidaySummary(202604), '');
    expect(holidaySummary(202801), '');
  });
}
