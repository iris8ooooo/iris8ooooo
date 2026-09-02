import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/month_grid.dart';

void main() {
  group('ym 연산', () {
    test('next/prev 연 경계', () {
      expect(nextYm(202612), 202701);
      expect(prevYm(202701), 202612);
      expect(nextYm(202608), 202609);
      expect(prevYm(202608), 202607);
    });

    test('ymAddMonths / ymDiff', () {
      expect(ymAddMonths(202608, 5), 202701);
      expect(ymAddMonths(202608, -8), 202512);
      expect(ymAddMonths(202601, -1), 202512);
      expect(ymDiff(202701, 202608), 5);
      expect(ymDiff(202608, 202701), -5);
      for (var i = -30; i <= 30; i++) {
        expect(ymDiff(ymAddMonths(202608, i), 202608), i);
      }
    });

    test('daysInMonth (윤년 포함)', () {
      expect(daysInMonth(202602), 28);
      expect(daysInMonth(202802), 29); // 2028 윤년
      expect(daysInMonth(202608), 31);
      expect(daysInMonth(202609), 30);
      expect(daysInMonth(202612), 31);
    });
  });

  group('monthGridDateKeys — 일요일 시작 42칸', () {
    test('2026년 8월: 1일은 토요일 → 첫 칸은 7/26(일)', () {
      final grid = monthGridDateKeys(202608);
      expect(grid.length, 42);
      expect(grid.first, 20260726);
      expect(grid[6], 20260801); // 첫 주 마지막 칸(토) = 8/1
      expect(grid.contains(20260831), true);
    });

    test('매월 1일과 말일이 반드시 포함된다 (경쟁앱 1일 버그 회귀 방지)', () {
      for (var ym = 202501; ym <= 202812; ym = nextYm(ym)) {
        final grid = monthGridDateKeys(ym);
        expect(grid.contains(ym * 100 + 1), true, reason: '$ym 1일 누락');
        expect(
          grid.contains(ym * 100 + daysInMonth(ym)),
          true,
          reason: '$ym 말일 누락',
        );
      }
    });

    test('해당 월의 모든 날짜가 정확히 한 번씩 등장한다', () {
      for (final ym in [202601, 202602, 202612, 202802]) {
        final grid = monthGridDateKeys(ym);
        for (var day = 1; day <= daysInMonth(ym); day++) {
          expect(
            grid.where((k) => k == ym * 100 + day).length,
            1,
            reason: '$ym-$day',
          );
        }
      }
    });

    test('42칸이 연속된 날짜다 (빈 칸/건너뜀 없음)', () {
      final grid = monthGridDateKeys(202612); // 12월 → 1월 연 경계 포함
      for (var i = 1; i < grid.length; i++) {
        final prev = DateTime(
          grid[i - 1] ~/ 10000,
          (grid[i - 1] % 10000) ~/ 100,
          grid[i - 1] % 100,
        );
        final curr = DateTime(
          grid[i] ~/ 10000,
          (grid[i] % 10000) ~/ 100,
          grid[i] % 100,
        );
        expect(
          curr.difference(prev).inDays,
          1,
          reason: '${grid[i - 1]} 다음이 ${grid[i]}',
        );
      }
    });

    test('첫 칸은 항상 주 시작 요일이다', () {
      for (var ym = 202501; ym <= 202712; ym = nextYm(ym)) {
        final first = monthGridDateKeys(ym).first;
        final weekday = DateTime(
          first ~/ 10000,
          (first % 10000) ~/ 100,
          first % 100,
        ).weekday;
        expect(weekday, DateTime.sunday, reason: '$ym');
      }
    });

    test('월요일 시작 설정도 지원한다', () {
      final grid = monthGridDateKeys(202608, weekStartWeekday: DateTime.monday);
      expect(grid.first, 20260727); // 8/1(토)이 포함된 주의 월요일 = 7/27
      final weekday = DateTime(2026, 7, 27).weekday;
      expect(weekday, DateTime.monday);
    });
  });

  group('weekdayOrder', () {
    test('일요일 시작', () {
      expect(weekdayOrder(), [7, 1, 2, 3, 4, 5, 6]); // 일 월 화 수 목 금 토
    });
    test('월요일 시작', () {
      expect(weekdayOrder(weekStartWeekday: DateTime.monday), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
    });
  });
}
