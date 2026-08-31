import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/month_summary.dart';

void main() {
  group('buildMonthSummary', () {
    test('빈 달', () {
      final s = buildMonthSummary({});
      expect(s.totalCenti, 0);
      expect(s.workedDays, 0);
      expect(s.entryCount, 0);
      expect(s.grossWon, null);
      expect(s.netWon, null);
    });

    test('하루 여러 건 합산 (오전/오후 + 잔업)', () {
      final s = buildMonthSummary({
        20260801: [100, 50], // 본공수 + 반공
        20260802: [100, 150], // 본공수 + 잔업
      });
      expect(s.totalCenti, 400);
      expect(s.workedDays, 2);
      expect(s.entryCount, 4);
    });

    test('휴무(0)만 있는 날은 근무일에서 제외, 기록 수에는 포함', () {
      final s = buildMonthSummary({
        20260801: [100],
        20260802: [0], // 휴무
        20260803: [0, 100], // 휴무 기록 + 근무
      });
      expect(s.totalCenti, 200);
      expect(s.workedDays, 2); // 1일, 3일
      expect(s.entryCount, 4);
    });

    test('한 달 시나리오: 22×1.0 + 4×1.5 + 1×0.5 = 28.5공수', () {
      final byDay = <int, List<int>>{};
      for (var d = 1; d <= 22; d++) {
        byDay[20260800 + d] = [100];
      }
      for (var d = 23; d <= 26; d++) {
        byDay[20260800 + d] = [150];
      }
      byDay[20260827] = [50];
      final s = buildMonthSummary(byDay);
      expect(s.totalCenti, 2850);
      expect(s.workedDays, 27);
      expect(s.entryCount, 27);
    });
  });
}
