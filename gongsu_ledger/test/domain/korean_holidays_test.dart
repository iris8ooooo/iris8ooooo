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
}
