import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/month_money.dart';
import 'package:gongsu_ledger/domain/rate_resolver.dart';

void main() {
  const histories = <RateHistoryEntry>[
    (siteId: 1, effectiveFromDateKey: 20260101, dailyRateWon: 150000),
    (siteId: 1, effectiveFromDateKey: 20260820, dailyRateWon: 165000),
  ];

  test('빈 달은 의미 없는 0', () {
    final m = buildMonthMoney(
      entries: const [],
      histories: histories,
      items: const [],
    );
    expect(m.grossWon, 0);
    expect(m.isMeaningful, false);
  });

  test('단가 인상이 월 중간에 있으면 날짜별로 다른 단가가 적용된다', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260819,
          centiGongsu: 100,
          siteId: 1,
          unitRateWonOverride: null,
        ),
        (
          dateKey: 20260820,
          centiGongsu: 100,
          siteId: 1,
          unitRateWonOverride: null,
        ),
        (
          dateKey: 20260821,
          centiGongsu: 150,
          siteId: 1,
          unitRateWonOverride: null,
        ),
      ],
      histories: histories,
      items: const [],
    );
    expect(m.laborWon, 150000 + 165000 + 247500);
    expect(m.pricedEntryCount, 3);
    expect(m.unpricedCenti, 0);
    expect(m.isMeaningful, true);
  });

  test('업체 미지정 기록은 공수만 집계되고 unpricedCenti로 드러난다', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260805,
          centiGongsu: 100,
          siteId: 1,
          unitRateWonOverride: null,
        ),
        (
          dateKey: 20260806,
          centiGongsu: 180,
          siteId: null,
          unitRateWonOverride: null,
        ),
      ],
      histories: histories,
      items: const [],
    );
    expect(m.laborWon, 150000);
    expect(m.unpricedCenti, 180);
  });

  test('날짜별 오버라이드 단가가 우선한다', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260805,
          centiGongsu: 100,
          siteId: 1,
          unitRateWonOverride: 200000,
        ),
      ],
      histories: histories,
      items: const [],
    );
    expect(m.laborWon, 200000);
  });

  test('부가항목: 가산은 더하고 공제는 뺀다', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260805,
          centiGongsu: 100,
          siteId: 1,
          unitRateWonOverride: null,
        ),
      ],
      histories: histories,
      items: const [
        (isDeduction: false, amountWon: 10000), // 식비
        (isDeduction: false, amountWon: 30000), // 일비
        (isDeduction: true, amountWon: 15000), // 안전용품비
      ],
    );
    expect(m.allowanceWon, 40000);
    expect(m.deductionWon, 15000);
    expect(m.grossWon, 150000 + 40000 - 15000);
    expect(m.itemCount, 3);
  });

  test('부가항목만 있어도 의미 있는 금액이다', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260805,
          centiGongsu: 100,
          siteId: null,
          unitRateWonOverride: null,
        ),
      ],
      histories: const [],
      items: const [(isDeduction: false, amountWon: 5000)],
    );
    expect(m.isMeaningful, true);
    expect(m.grossWon, 5000);
    expect(m.unpricedCenti, 100);
  });

  test('한 달 시나리오 — 정수 연산 정확성 (0.05 단위 × 홀수 단가)', () {
    final m = buildMonthMoney(
      entries: const [
        (
          dateKey: 20260805,
          centiGongsu: 5,
          siteId: 1,
          unitRateWonOverride: 175433,
        ),
        (
          dateKey: 20260806,
          centiGongsu: 285,
          siteId: 1,
          unitRateWonOverride: 199999,
        ),
      ],
      histories: histories,
      items: const [],
    );
    expect(m.laborWon, 8771 + 569997); // 각각 1원 미만 절사
  });
}
