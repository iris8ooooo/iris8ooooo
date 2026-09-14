import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gongsu_value.dart';
import '../../domain/marker_palette.dart';
import '../../domain/month_grid.dart';
import '../../domain/stats.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';
import '../app_theme.dart';
import '../common/app_icons.dart';
import '../common/tab_header.dart';
import '../common/won_format.dart';
import '../home/ink_nav_bar.dart';

/// 통계 — 연간 요약, 월별 막대(공수 · 실수령), 업체별 합산.
/// 그래프는 외부 패키지 없이 가로 막대로 — 큰글씨/다크모드에 안전.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stats = ref.watch(yearStatsProvider(_year));
    final siteById = ref.watch(siteByIdProvider);
    final brightness = Theme.of(context).brightness;
    final thisYm = ymOf(DateTime.now().year, DateTime.now().month);

    return Scaffold(
      bottomNavigationBar: const NavSpacer(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const TabHeader(title: '통계'),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: '이전 해',
                    icon: Icon(AppIcons.chevronLeft, color: c.muted),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text(
                    '$_year년',
                    key: const ValueKey('stats-year'),
                    style: AppFonts.displayStyle(size: 26, color: c.text),
                  ),
                  IconButton(
                    tooltip: '다음 해',
                    icon: Icon(AppIcons.chevronRight, color: c.muted),
                    onPressed: () => setState(() => _year++),
                  ),
                ],
              ),
            ),
            if (stats == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _YearGrid(stats: stats),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel(stats.hasMoney ? '월별 공수 · 실수령' : '월별 공수'),
                    for (final m in stats.months)
                      _MonthBar(
                        stat: m,
                        maxCenti: stats.maxMonthCenti,
                        showMoney: stats.hasMoney,
                        isCurrent: m.ym == thisYm,
                      ),
                  ],
                ),
              ),
              if (stats.sites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('업체별'),
                      for (final s in stats.sites)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: s.siteId == null
                                      ? c.muted
                                      : MarkerPalette.colorOf(
                                          siteById[s.siteId]?.colorId ?? 0,
                                          brightness: brightness,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.siteId == null
                                          ? '업체 미지정'
                                          : (siteById[s.siteId]?.name ??
                                                '삭제된 업체'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: c.text,
                                      ),
                                    ),
                                    Text(
                                      '${formatGongsu(s.centi)} 공수 · ${s.workedDays}일',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (stats.hasMoney && s.grossWon > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatWon(s.netWon),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: c.text,
                                      ),
                                    ),
                                    if (s.netWon != s.grossWon)
                                      Text(
                                        '세전 ${formatWon(s.grossWon)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: c.muted,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// 연간 요약 2×2: 연간 공수 · 근무일 / 연간 세전 · 연간 실수령.
class _YearGrid extends StatelessWidget {
  const _YearGrid({required this.stats});

  final YearStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget cell(
      String label,
      String value, {
      String? unit,
      String? key,
      double size = 26,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c.muted,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
              ],
            ),
            key: key == null ? null : ValueKey(key),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: cell(
                  '연간 공수',
                  formatGongsu(stats.totalCenti),
                  key: 'year-centi',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: cell('근무일', '${stats.totalWorkedDays}', unit: ' 일'),
              ),
            ],
          ),
          if (stats.hasMoney) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: cell('연간 세전', formatWon(stats.grossWon), size: 17),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: cell(
                    '연간 실수령',
                    formatWon(stats.netWon),
                    key: 'year-net',
                    size: 17,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.stat,
    required this.maxCenti,
    required this.showMoney,
    required this.isCurrent,
  });

  final MonthStat stat;
  final int maxCenti;
  final bool showMoney;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final has = stat.centi > 0;
    // 막대 폭 비율: 정수 퍼밀(‰)로 계산해 double 산술을 피한다. 값이 있으면
    // 최소 8% 는 보이게.
    final permille = maxCenti == 0
        ? 0
        : ((stat.centi * 1000) ~/ maxCenti).clamp(has ? 80 : 0, 1000);
    final labelColor = has ? c.text : c.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${monthOfYm(stat.ym)}월',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: c.tint05,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: permille / 1000,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: isCurrent ? c.tint20 : c.tint15,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                has ? formatGongsu(stat.centi) : '–',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: labelColor,
                ),
              ),
            ),
          ),
          if (showMoney)
            SizedBox(
              width: 76,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  stat.hasMoney ? _digits(stat.netWon) : '',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _digits(int won) {
    final s = formatWon(won);
    return s.endsWith('원') ? s.substring(0, s.length - 1) : s;
  }
}
