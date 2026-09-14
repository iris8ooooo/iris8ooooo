import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/range_fill.dart';

void main() {
  test('2026년 9월 15~30일: 일요일(20·27)·추석(24~26)·대체휴일(28) 제외 → 10일', () {
    final plan = planRangeFill(
      fromKey: 20260915,
      toKey: 20260930,
      skipRestDays: true,
      occupied: const {},
    );
    expect(plan.dateKeys, [
      20260915,
      20260916,
      20260917,
      20260918,
      20260919,
      20260921,
      20260922,
      20260923,
      20260929,
      20260930,
    ]);
    expect(plan.skippedRest, 6);
    expect(plan.skippedOccupied, 0);
  });

  test('이미 기록이 있는 날은 건너뛴다 (두 번 기록 금지)', () {
    final plan = planRangeFill(
      fromKey: 20260915,
      toKey: 20260930,
      skipRestDays: true,
      occupied: const {20260916, 20260920}, // 20은 일요일이기도 함
    );
    expect(plan.dateKeys, isNot(contains(20260916)));
    expect(plan.dateKeys.length, 9);
    expect(plan.skippedOccupied, 2); // 기록 있음이 쉬는 날보다 먼저 판정
    expect(plan.skippedRest, 5);
  });

  test('쉬는 날 포함이면 전부 채운다, 월·연 경계를 넘는다', () {
    final plan = planRangeFill(
      fromKey: 20261230,
      toKey: 20270102,
      skipRestDays: false,
      occupied: const {},
    );
    expect(plan.dateKeys, [20261230, 20261231, 20270101, 20270102]);
  });

  test('종료일이 시작일보다 앞이면 빈 계획, 62일 상한', () {
    expect(
      planRangeFill(
        fromKey: 20260915,
        toKey: 20260914,
        skipRestDays: false,
        occupied: const {},
      ).dateKeys,
      isEmpty,
    );
    final long = planRangeFill(
      fromKey: 20260101,
      toKey: 20261231,
      skipRestDays: false,
      occupied: const {},
    );
    expect(long.dateKeys.length, maxRangeFillDays);
    expect(long.dateKeys.last, 20260303);
  });

  test('말일·날짜 더하기', () {
    expect(monthEndKeyOf(20260215), 20260228);
    expect(monthEndKeyOf(20240215), 20240229);
    expect(monthEndKeyOf(20260901), 20260930);
    expect(addDaysToKey(20260930, 1), 20261001);
    expect(addDaysToKey(20261231, 6), 20270106);
    expect(isRestDay(20260920), true); // 일요일
    expect(isRestDay(20260925), true); // 추석
    expect(isRestDay(20260919), false); // 토요일은 쉬는 날 아님
  });
}
