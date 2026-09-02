/// 단가 해석 — 순수 함수.
///
/// 단가는 기록에 저장하지 않고 조회 시점에 이력에서 해석한다. 그래서
/// "단가가 올랐는데 다음 달부터 새 단가로, 이전 기록은 그대로"라는
/// 요구가 데이터 구조 자체로 보장된다 (경쟁앱은 단가를 바꾸면 과거 기록까지
/// 바뀌는 문제가 있었다).
library;

/// 단가 이력 한 건의 도메인 뷰 (drift 행에서 변환해 넘긴다).
typedef RateHistoryEntry = ({
  int siteId,
  int effectiveFromDateKey,
  int dailyRateWon,
});

/// 특정 날짜에 적용되는 업체 단가.
/// 이력 중 `effectiveFrom <= dateKey`인 것 가운데 가장 늦은 시작일의 단가.
/// 해당 없으면 null (단가 미설정 — 금액 계산 불가, 공수만 집계).
int? resolveSiteRateWon({
  required Iterable<RateHistoryEntry> histories,
  required int siteId,
  required int dateKey,
}) {
  int? bestFrom;
  int? bestRate;
  for (final h in histories) {
    if (h.siteId != siteId || h.effectiveFromDateKey > dateKey) continue;
    if (bestFrom == null || h.effectiveFromDateKey > bestFrom) {
      bestFrom = h.effectiveFromDateKey;
      bestRate = h.dailyRateWon;
    }
  }
  return bestRate;
}

/// 기록 한 건의 적용 단가: 날짜별 오버라이드 > 업체 단가 이력 > null.
int? resolveEntryRateWon({
  required int dateKey,
  required int? siteId,
  required int? unitRateWonOverride,
  required Iterable<RateHistoryEntry> histories,
}) {
  if (unitRateWonOverride != null) return unitRateWonOverride;
  if (siteId == null) return null;
  return resolveSiteRateWon(
    histories: histories,
    siteId: siteId,
    dateKey: dateKey,
  );
}
