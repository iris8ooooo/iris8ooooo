import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/day_item_repository.dart';
import '../domain/date_key.dart';
import '../domain/month_grid.dart';
import '../domain/month_money.dart';
import '../domain/month_summary.dart';
import 'db_providers.dart';
import 'site_providers.dart';
import 'tax_providers.dart';

/// 현재 보이는 달 (yyyyMM). family 키는 전부 int — 객체 키의 ==/hashCode
/// 실수로 인한 캐시 미스·중복 구독을 차단한다.
final visibleYmProvider = NotifierProvider<VisibleYmNotifier, int>(
  VisibleYmNotifier.new,
);

class VisibleYmNotifier extends Notifier<int> {
  @override
  int build() => ymOfDateKey(dateKeyOf(DateTime.now()));

  void set(int ym) => state = ym;
}

/// 한 달치 기록: dateKey → 그 날의 기록 목록.
/// 월 쿼리 1회가 유일한 소스 — 달력 셀, 월 합계, 입력 시트가 전부 여기서
/// 파생되어 같은 스트림 이벤트로 동시에 갱신된다.
final monthEntriesProvider = StreamProvider.autoDispose
    .family<Map<int, List<WorkEntry>>, int>((ref, ym) {
      final dao = ref.watch(databaseProvider).workEntryDao;
      return dao.watchMonth(ym).map((rows) {
        final byDay = <int, List<WorkEntry>>{};
        for (final row in rows) {
          (byDay[row.dateKey] ??= []).add(row);
        }
        return byDay;
      });
    });

/// 한 달치 부가 항목: dateKey → 항목 목록.
final monthExtraItemsProvider = StreamProvider.autoDispose
    .family<Map<int, List<DayExtraItem>>, int>((ref, ym) {
      final dao = ref.watch(databaseProvider).dayItemDao;
      return dao.watchMonth(ym).map((rows) {
        final byDay = <int, List<DayExtraItem>>{};
        for (final row in rows) {
          (byDay[row.dateKey] ??= []).add(row);
        }
        return byDay;
      });
    });

/// 특정 날짜의 부가 항목 — monthExtraItems에서 select.
final dayExtraItemsProvider = Provider.autoDispose
    .family<List<DayExtraItem>, int>((ref, dateKey) {
      final async = ref.watch(monthExtraItemsProvider(ymOfDateKey(dateKey)));
      return async.valueOrNull?[dateKey] ?? const [];
    });

/// 월 금액 집계 — 기록 + 전체 단가 이력 + 부가 항목에서 파생.
final monthMoneyProvider = Provider.autoDispose.family<MonthMoney, int>((
  ref,
  ym,
) {
  final byDay = ref.watch(monthEntriesProvider(ym)).valueOrNull;
  if (byDay == null) return MonthMoney.empty;
  final rates =
      ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
  final itemsByDay =
      ref.watch(monthExtraItemsProvider(ym)).valueOrNull ??
      const <int, List<DayExtraItem>>{};
  return buildMonthMoney(
    entries: [
      for (final list in byDay.values)
        for (final w in list)
          (
            dateKey: w.dateKey,
            centiGongsu: w.centiGongsu,
            siteId: w.siteId,
            unitRateWonOverride: w.unitRateWonOverride,
          ),
    ],
    histories: [
      for (final r in rates)
        (
          siteId: r.siteId,
          effectiveFromDateKey: r.effectiveFromDateKey,
          dailyRateWon: r.dailyRateWon,
        ),
    ],
    items: [
      for (final list in itemsByDay.values)
        for (final it in list)
          (
            isDeduction:
                ExtraItemKind.fromCode(it.kind) == ExtraItemKind.deduction,
            amountWon: it.amountWon,
          ),
    ],
  );
});

/// 월 합계 — monthEntries + monthMoney에서 파생 (쿼리 추가 없음).
/// grossWon은 금액 정보가 하나라도 있을 때만 채운다 (없으면 null → 카드 숨김).
final monthSummaryProvider = Provider.autoDispose.family<MonthSummary, int>((
  ref,
  ym,
) {
  final async = ref.watch(monthEntriesProvider(ym));
  final byDay = async.valueOrNull;
  if (byDay == null) return MonthSummary.empty;
  final base = buildMonthSummary({
    for (final e in byDay.entries)
      e.key: [for (final w in e.value) w.centiGongsu],
  });
  final money = ref.watch(monthMoneyProvider(ym));
  final settlement = ref.watch(monthSettlementProvider(ym));
  return base.withMoney(
    grossWon: money.isMeaningful ? money.grossWon : null,
    netWon: money.isMeaningful ? settlement.netWon : null,
  );
});

/// 특정 날짜의 기록 — monthEntries에서 select (쿼리 추가 없음).
final dayEntriesProvider = Provider.autoDispose.family<List<WorkEntry>, int>((
  ref,
  dateKey,
) {
  final async = ref.watch(monthEntriesProvider(ymOfDateKey(dateKey)));
  return async.valueOrNull?[dateKey] ?? const [];
});

/// 한 달 중 메모가 있는 날짜 키 — 달력 셀 표시용.
final monthMemoKeysProvider = StreamProvider.autoDispose.family<Set<int>, int>((
  ref,
  ym,
) {
  final dao = ref.watch(databaseProvider).memoDao;
  return dao.watchMonthMemoKeys(ym);
});

/// 특정 날짜의 메모.
final dayMemoProvider = StreamProvider.autoDispose.family<DayMemo?, int>((
  ref,
  dateKey,
) {
  final dao = ref.watch(databaseProvider).memoDao;
  return dao.watchMemo(dateKey);
});
