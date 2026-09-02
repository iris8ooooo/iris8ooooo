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
class MonthView extends ConsumerWidget {
  const MonthView({
    super.key,
    required this.ym,
    required this.onOutsideMonthTap,
  });

  final int ym;

  /// 이웃 달 칸을 탭하면 그 달로 이동.
  final void Function(int ym) onOutsideMonthTap;

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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        children: [
          for (var week = 0; week < 6; week++)
            Expanded(
              child: Row(
                children: [
                  for (var day = 0; day < 7; day++)
                    Expanded(
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
