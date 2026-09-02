import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gongsu_value.dart';
import '../../domain/month_grid.dart';
import '../../state/calendar_providers.dart';
import '../../state/tax_providers.dart';
import '../common/won_format.dart';

/// 달력 위 상시 표시되는 월 합계 카드.
/// 세전 예상 수입은 업체 단가/부가항목이 하나라도 있을 때만 보인다.
/// 세후 실수령(netWon)은 M3 세금 정산에서 추가된다.
class MonthSummaryCard extends ConsumerWidget {
  const MonthSummaryCard({super.key, required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider(ym));
    final money = ref.watch(monthMoneyProvider(ym));
    final settlement = ref.watch(monthSettlementProvider(ym));
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${monthOfYm(ym)}월 총 공수',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatGongsu(summary.totalCenti)} 공수',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '근무일',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.workedDays}일',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (summary.grossWon != null) ...[
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '예상 수입 (세전)',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formatWon(summary.grossWon!),
                    key: const ValueKey('gross-won'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (money.unpricedCenti > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '단가 없는 ${formatGongsu(money.unpricedCenti)}공수는 제외',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ),
              if (summary.netWon != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        settlement.tax.isZero ? '실수령 (공제 없음)' : '실수령 (세후)',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      formatWon(summary.netWon!),
                      key: const ValueKey('net-won'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                if (!settlement.tax.isZero)
                  Text(
                    '세금·보험 공제 ${formatWon(settlement.tax.totalWon)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else if (!settlement.hasTaxConfigured)
                  Text(
                    '업체 수정 → 세금 방식을 고르면 공제가 계산돼요',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
