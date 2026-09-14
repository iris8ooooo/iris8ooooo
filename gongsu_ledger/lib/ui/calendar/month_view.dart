import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/date_key.dart';
import '../../domain/korean_holidays.dart';
import '../../domain/month_grid.dart';
import '../../state/appearance_providers.dart';
import '../../state/calendar_providers.dart';
import '../../state/site_providers.dart';
import '../entry_sheet/entry_sheet.dart';
import 'day_cell.dart';

/// 한 달 달력 격자 (고정 6주 42칸 — 월마다 높이가 출렁이지 않는다).
/// 칸 사이는 3px, 좌우 여백은 요일 줄·범례와 같은 [horizontalPadding].
class MonthView extends ConsumerWidget {
  const MonthView({
    super.key,
    required this.ym,
    required this.onOutsideMonthTap,
  });

  final int ym;

  /// 이웃 달 칸을 탭하면 그 달로 이동.
  final void Function(int ym) onOutsideMonthTap;

  /// 격자 좌우 여백 (칸 사이 간격의 절반을 뺀 값 — 칸 가장자리가 14px 에 맞는다).
  static const double horizontalPadding = 12.5;

  /// 칸 사이 간격의 절반 (각 칸이 사방 이만큼 띄운다).
  static const double cellGap = 1.5;

  /// 격자 전체 높이 상한 — 시안의 칸 높이 62px × 6줄 + 간격·아래 여백.
  static const double maxHeight = (62 + cellGap * 2) * 6 + 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesByDay =
        ref.watch(monthEntriesProvider(ym)).valueOrNull ??
        const <int, List<Never>>{};
    final memoKeys =
        ref.watch(monthMemoKeysProvider(ym)).valueOrNull ?? const <int>{};
    final siteById = ref.watch(siteByIdProvider);
    final weekStart = ref.watch(
      appearanceProvider.select((a) => a.weekStart.weekday),
    );
    final dateKeys = monthGridDateKeys(ym, weekStartWeekday: weekStart);
    final todayKey = dateKeyOf(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        2,
      ),
      child: Column(
        children: [
          for (var week = 0; week < 6; week++)
            Expanded(
              child: Row(
                children: [
                  for (var day = 0; day < 7; day++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(cellGap),
                        child: Builder(
                          builder: (context) {
                            final dateKey = dateKeys[week * 7 + day];
                            final inMonth = ymOfDateKey(dateKey) == ym;
                            return DayCell(
                              key: ValueKey('day-$dateKey'),
                              dateKey: dateKey,
                              inMonth: inMonth,
                              isToday: dateKey == todayKey,
                              entries: inMonth
                                  ? (entriesByDay[dateKey] ?? const [])
                                  : const [],
                              hasMemo: inMonth && memoKeys.contains(dateKey),
                              siteById: siteById,
                              holidayName: inMonth
                                  ? koreanHolidayName(dateKey)
                                  : null,
                              onTap: () {
                                if (inMonth) {
                                  showEntrySheet(context, dateKey);
                                } else {
                                  onOutsideMonthTap(ymOfDateKey(dateKey));
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
