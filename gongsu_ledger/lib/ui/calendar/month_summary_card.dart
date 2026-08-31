import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gongsu_value.dart';
import '../../domain/month_grid.dart';
import '../../state/calendar_providers.dart';

/// 달력 위 상시 표시되는 월 합계 카드.
/// 금액(세전/세후)은 M2 단가·M3 세금에서 이 카드에 추가된다
/// (MonthSummary.grossWon/netWon 자리 확보 완료).
class MonthSummaryCard extends ConsumerWidget {
  const MonthSummaryCard({super.key, required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider(ym));
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monthOfYm(ym)}월 총 공수',
                    style: TextStyle(
                        fontSize: 14, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatGongsu(summary.totalCenti)} 공수',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '근무일',
                  style:
                      TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.workedDays}일',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
