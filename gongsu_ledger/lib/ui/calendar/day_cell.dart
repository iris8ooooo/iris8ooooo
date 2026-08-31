import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/marker_palette.dart';

/// 달력 날짜 칸. 셀의 정체성은 dateKey(yyyyMMdd int) — 탭 이벤트는 이 int를
/// 그대로 전달하며 DateTime 변환이 다시 등장하지 않는다.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.dateKey,
    required this.inMonth,
    required this.isToday,
    required this.entries,
    required this.hasMemo,
    required this.onTap,
  });

  final int dateKey;
  final bool inMonth;
  final bool isToday;
  final List<WorkEntry> entries;
  final bool hasMemo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final day = dateKey % 100;
    final weekday = dateFromKey(dateKey).weekday;

    final dayColor = !inMonth
        ? scheme.onSurface.withValues(alpha: 0.25)
        : switch (weekday) {
            DateTime.sunday => scheme.error,
            DateTime.saturday => scheme.primary,
            _ => scheme.onSurface,
          };

    var totalCenti = 0;
    for (final e in entries) {
      totalCenti += e.centiGongsu;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: scheme.primary, width: 2)
              : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w500,
                      color: dayColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (entries.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  totalCenti > 0 ? formatGongsu(totalCenti) : '휴',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: totalCenti > 0
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final e in entries.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MarkerPalette.colorOf(e.colorIdSnapshot),
                        ),
                      ),
                    ),
                  if (hasMemo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          color: scheme.tertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
