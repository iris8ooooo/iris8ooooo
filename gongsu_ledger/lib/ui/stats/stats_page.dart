import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gongsu_value.dart';
import '../../domain/month_grid.dart';
import '../../domain/stats.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';
import '../common/won_format.dart';

/// 통계 — 월별 추이, 연간 누적(연봉 뷰), 업체별 합산.
/// 그래프는 외부 패키지 없이 막대(가로)로 그린다 — 큰글씨/다크모드에 안전.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = ref.watch(yearStatsProvider(_year));
    final siteById = ref.watch(siteByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '이전 해',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '$_year년',
                key: const ValueKey('stats-year'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: '다음 해',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          if (stats == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _YearCard(stats: stats),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '월별 추이',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final m in stats.months)
                      _MonthBar(
                        stat: m,
                        maxCenti: stats.maxMonthCenti,
                        showMoney: stats.hasMoney,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (stats.sites.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '업체별',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      for (final s in stats.sites)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            s.siteId == null
                                ? '업체 미지정'
                                : (siteById[s.siteId]?.name ?? '삭제된 업체'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${formatGongsu(s.centi)} 공수 · ${s.workedDays}일',
                          ),
                          trailing: stats.hasMoney && s.grossWon > 0
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatWon(s.netWon),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '세전 ${formatWon(s.grossWon)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.stats});

  final YearStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget cell(String label, String value, {String? key}) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: key == null ? null : ValueKey(key),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                cell(
                  '연간 공수',
                  formatGongsu(stats.totalCenti),
                  key: 'year-centi',
                ),
                cell('근무일', '${stats.totalWorkedDays}일'),
              ],
            ),
            if (stats.hasMoney) ...[
              const Divider(height: 20),
              Row(
                children: [
                  cell('연간 세전', formatWon(stats.grossWon)),
                  cell('연간 실수령', formatWon(stats.netWon), key: 'year-net'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.stat,
    required this.maxCenti,
    required this.showMoney,
  });

  final MonthStat stat;
  final int maxCenti;
  final bool showMoney;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 막대 폭 비율: 정수 퍼밀(‰)로 계산해 double 산술을 피한다.
    final permille = maxCenti == 0 ? 0 : (stat.centi * 1000) ~/ maxCenti;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${monthOfYm(stat.ym)}월',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: permille / 1000,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              stat.centi == 0 ? '-' : formatGongsu(stat.centi),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (showMoney)
            SizedBox(
              width: 92,
              child: Text(
                stat.hasMoney ? formatWon(stat.netWon) : '',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
