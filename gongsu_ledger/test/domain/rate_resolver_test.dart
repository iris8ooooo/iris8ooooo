import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/rate_resolver.dart';

void main() {
  const histories = <RateHistoryEntry>[
    (siteId: 1, effectiveFromDateKey: 20260101, dailyRateWon: 150000),
    (siteId: 1, effectiveFromDateKey: 20260901, dailyRateWon: 165000), // 인상
    (siteId: 2, effectiveFromDateKey: 20260601, dailyRateWon: 200000),
  ];

  group('resolveSiteRateWon — 적용 시작일 기준', () {
    test('인상 전 날짜는 옛 단가, 인상 당일부터 새 단가', () {
      expect(
        resolveSiteRateWon(histories: histories, siteId: 1, dateKey: 20260831),
        150000,
      );
      expect(
        resolveSiteRateWon(histories: histories, siteId: 1, dateKey: 20260901),
        165000,
      ); // 당일 포함
      expect(
        resolveSiteRateWon(histories: histories, siteId: 1, dateKey: 20261231),
        165000,
      );
    });

    test('첫 이력 시작일 이전은 단가 없음(null) — 임의 추정 금지', () {
      expect(
        resolveSiteRateWon(histories: histories, siteId: 1, dateKey: 20251231),
        null,
      );
      expect(
        resolveSiteRateWon(histories: histories, siteId: 2, dateKey: 20260531),
        null,
      );
    });

    test('다른 업체 이력은 섞이지 않는다', () {
      expect(
        resolveSiteRateWon(histories: histories, siteId: 2, dateKey: 20260901),
        200000,
      );
      expect(
        resolveSiteRateWon(histories: histories, siteId: 3, dateKey: 20260901),
        null,
      );
    });

    test('이력 순서와 무관하게 같은 결과', () {
      final shuffled = histories.reversed.toList();
      expect(
        resolveSiteRateWon(histories: shuffled, siteId: 1, dateKey: 20260915),
        165000,
      );
      expect(
        resolveSiteRateWon(histories: shuffled, siteId: 1, dateKey: 20260815),
        150000,
      );
    });
  });

  group('resolveEntryRateWon — 오버라이드 우선', () {
    test('날짜별 오버라이드가 업체 이력을 이긴다', () {
      expect(
        resolveEntryRateWon(
          dateKey: 20260915,
          siteId: 1,
          unitRateWonOverride: 180000,
          histories: histories,
        ),
        180000,
      );
    });

    test('오버라이드 없으면 업체 이력', () {
      expect(
        resolveEntryRateWon(
          dateKey: 20260915,
          siteId: 1,
          unitRateWonOverride: null,
          histories: histories,
        ),
        165000,
      );
    });

    test('업체 없고 오버라이드도 없으면 null', () {
      expect(
        resolveEntryRateWon(
          dateKey: 20260915,
          siteId: null,
          unitRateWonOverride: null,
          histories: histories,
        ),
        null,
      );
    });

    test('업체 없이 오버라이드만 있어도 금액 계산 가능', () {
      expect(
        resolveEntryRateWon(
          dateKey: 20260915,
          siteId: null,
          unitRateWonOverride: 120000,
          histories: histories,
        ),
        120000,
      );
    });
  });
}
