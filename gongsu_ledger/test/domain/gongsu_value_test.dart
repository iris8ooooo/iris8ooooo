import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/domain/gongsu_value.dart';

void main() {
  group('tryParseGongsu — 반올림 없이 정확히 파싱', () {
    test('경쟁앱 버그 케이스: 1.8은 1.8이다 (2.0 반올림 금지)', () {
      expect(tryParseGongsu('1.8'), 180);
      expect(formatGongsu(tryParseGongsu('1.8')!), '1.8');
    });

    test('기본 케이스', () {
      expect(tryParseGongsu('1'), 100);
      expect(tryParseGongsu('1.0'), 100);
      expect(tryParseGongsu('0.5'), 50);
      expect(tryParseGongsu('0.05'), 5);
      expect(tryParseGongsu('2.35'), 235);
      expect(tryParseGongsu('0'), 0);
      expect(tryParseGongsu('1.4'), 140); // 경쟁앱에서 "안 된다"던 값
      expect(tryParseGongsu('0.9'), 90); // 조선소 A코드
    });

    test('관용 입력 허용', () {
      expect(tryParseGongsu('.5'), 50);
      expect(tryParseGongsu('1.'), 100);
      expect(tryParseGongsu(' 1.5 '), 150);
      expect(tryParseGongsu('1,5'), 150); // 쉼표 소수점 키패드
    });

    test('잘못된 입력은 조용히 변형하지 않고 거부', () {
      expect(tryParseGongsu(''), null);
      expect(tryParseGongsu('.'), null);
      expect(tryParseGongsu('abc'), null);
      expect(tryParseGongsu('1.855'), null); // 소수점 3자리 — 자르지 않고 거부
      expect(tryParseGongsu('-1'), null);
      expect(tryParseGongsu('1..5'), null);
      expect(tryParseGongsu('1.5.5'), null);
      expect(tryParseGongsu('1e2'), null);
      expect(tryParseGongsu('1234'), null); // 4자리 정수부
    });

    test('모든 0.05 단위 값이 0~10공수 구간에서 왕복 보존된다', () {
      for (var centi = 0; centi <= 1000; centi += 5) {
        final formatted = formatGongsu(centi);
        expect(tryParseGongsu(formatted), centi,
            reason: '$centi centi → "$formatted" → 파싱 왕복 실패');
      }
    });
  });

  group('isValidGongsuStep', () {
    test('0.05 단위 검증', () {
      expect(isValidGongsuStep(180), true);
      expect(isValidGongsuStep(5), true);
      expect(isValidGongsuStep(175), true);
      expect(isValidGongsuStep(133), false);
      expect(isValidGongsuStep(1), false);
    });
  });

  group('formatGongsu', () {
    test('후행 0 제거, 정수는 소수점 없음', () {
      expect(formatGongsu(200), '2');
      expect(formatGongsu(100), '1');
      expect(formatGongsu(180), '1.8');
      expect(formatGongsu(50), '0.5');
      expect(formatGongsu(5), '0.05');
      expect(formatGongsu(175), '1.75');
      expect(formatGongsu(0), '0');
      expect(formatGongsu(1050), '10.5');
    });
  });

  group('calcAmountWon — 정수 연산, 부동소수점 오차 없음', () {
    test('기본 계산', () {
      expect(calcAmountWon(centiGongsu: 100, dailyRateWon: 150000), 150000);
      expect(calcAmountWon(centiGongsu: 150, dailyRateWon: 150000), 225000);
      expect(calcAmountWon(centiGongsu: 180, dailyRateWon: 175000), 315000);
      expect(calcAmountWon(centiGongsu: 50, dailyRateWon: 175000), 87500);
    });

    test('나누어 떨어지지 않으면 1원 미만 절사 (규칙 고정)', () {
      // 0.05공수 × 175,433원 = 8,771.65 → 8,771원
      expect(calcAmountWon(centiGongsu: 5, dailyRateWon: 175433), 8771);
      // 0.9공수 × 111,111원 = 99,999.9 → 99,999원
      expect(calcAmountWon(centiGongsu: 90, dailyRateWon: 111111), 99999);
    });

    test('부동소수점이면 틀렸을 케이스', () {
      // double이면 0.1+0.2 류 오차가 나는 조합을 정수로 정확히 계산
      expect(calcAmountWon(centiGongsu: 10, dailyRateWon: 3), 0); // 0.3 절사
      expect(
          calcAmountWon(centiGongsu: 285, dailyRateWon: 199999), 569997); // 2.85공수
    });

    test('한 달 근무 합산 시나리오 (공수 합산 후 곱셈)', () {
      // 22일 × 1.0 + 4일 × 1.5 + 1일 × 0.5 = 28.5공수 × 165,000원
      const centiSum = 22 * 100 + 4 * 150 + 1 * 50;
      expect(centiSum, 2850);
      expect(calcAmountWon(centiGongsu: centiSum, dailyRateWon: 165000),
          4702500);
    });
  });

  group('dateKey', () {
    test('왕복 변환', () {
      final d = DateTime(2026, 8, 31);
      expect(dateKeyOf(d), 20260831);
      expect(dateFromKey(20260831), DateTime(2026, 8, 31));
      expect(dateKeyOf(DateTime(2026, 1, 1)), 20260101); // 매월 1일 버그 회귀 방지
      expect(dateFromKey(20260101), DateTime(2026, 1, 1));
    });

    test('월 범위', () {
      final (start, end) = monthKeyRange(2026, 2);
      expect(start, 20260201);
      expect(end, 20260231); // 키 비교용 상한 — 실존 날짜일 필요 없음
      expect(dateKeyOf(DateTime(2026, 2, 28)) <= end, true);
      expect(dateKeyOf(DateTime(2026, 3, 1)) > end, true);
    });

    test('시각 정보가 있어도 같은 키', () {
      expect(dateKeyOf(DateTime(2026, 8, 31, 23, 59, 59)), 20260831);
    });
  });
}
