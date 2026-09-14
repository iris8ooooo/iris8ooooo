import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/pro_limits.dart';
import '../../domain/settlement.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';
import '../app_theme.dart';
import '../common/app_icons.dart';
import '../common/ink_pill.dart';
import '../common/tab_header.dart';
import '../common/won_format.dart';
import '../export/report_export_page.dart';
import '../home/ink_nav_bar.dart';
import '../pro/pro_gate.dart';
import 'cycle_start_dialog.dart';

/// 기간 지정 정산 — 월초 기준이 아닌 임의 기간(예: 전월 21일~당월 20일 마감
/// 현장)의 업체별 공수·세전·공제·실수령. 숫자는 전부 정산 엔진 결과.
class SettlementPage extends ConsumerStatefulWidget {
  const SettlementPage({super.key});

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

enum _Period { thisMonth, lastMonth, cycle, custom }

class _SettlementPageState extends ConsumerState<SettlementPage> {
  late int _fromKey;
  late int _toKey;
  _Period _period = _Period.thisMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromKey = dateKeyOf(DateTime(now.year, now.month, 1));
    _toKey = dateKeyOf(DateTime(now.year, now.month + 1, 0));
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _period = _Period.thisMonth;
      _fromKey = dateKeyOf(DateTime(now.year, now.month, 1));
      _toKey = dateKeyOf(DateTime(now.year, now.month + 1, 0));
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _period = _Period.lastMonth;
      _fromKey = dateKeyOf(DateTime(now.year, now.month - 1, 1));
      _toKey = dateKeyOf(DateTime(now.year, now.month, 0));
    });
  }

  /// 마감 주기: 시작일이 21이면 "전월 21일 ~ 당월 20일" 중 오늘이 속한 구간.
  void _setCycle(int startDay) {
    final now = DateTime.now();
    final startMonth = now.day >= startDay ? now.month : now.month - 1;
    final from = DateTime(now.year, startMonth, startDay);
    final to = DateTime(from.year, from.month + 1, startDay - 1);
    setState(() {
      _period = _Period.cycle;
      _fromKey = dateKeyOf(from);
      _toKey = dateKeyOf(to);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = dateFromKey(isFrom ? _fromKey : _toKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isFrom ? '정산 시작일' : '정산 종료일',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = _Period.custom;
      if (isFrom) {
        _fromKey = dateKeyOf(picked);
        if (_toKey < _fromKey) _toKey = _fromKey;
      } else {
        _toKey = dateKeyOf(picked);
        if (_fromKey > _toKey) _fromKey = _toKey;
      }
    });
  }

  Future<void> _editCycleStartDay(int current) async {
    final chosen = await showCycleStartDialog(context, ref, current: current);
    if (chosen == null || !mounted) return;
    _setCycle(chosen);
  }

  static String _fmt(int key) {
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  /// "2026.9.1 ~ 9.30" — 같은 해면 뒤쪽 연도를 생략.
  static String _range(int from, int to) {
    final a = dateFromKey(from);
    final b = dateFromKey(to);
    final tail = a.year == b.year ? '${b.month}.${b.day}' : _fmt(to);
    return '${_fmt(from)} ~ $tail';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cycleStart = ref.watch(settleCycleStartDayProvider).valueOrNull ?? 1;
    final settlement = ref.watch(
      periodSettlementProvider(periodKey(_fromKey, _toKey)),
    );
    final siteById = ref.watch(siteByIdProvider);
    final dateStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: c.muted,
    );

    return Scaffold(
      bottomNavigationBar: const NavSpacer(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            TabHeader(
              title: '정산',
              actions: [
                IconButton(
                  key: const ValueKey('export-pdf'),
                  tooltip: '공수 확인서 PDF',
                  icon: const Icon(AppIcons.pdf),
                  onPressed: () async {
                    // 공수 확인서 PDF 는 프로 기능.
                    if (!await ensurePro(
                      context,
                      ref,
                      feature: ProFeature.pdf,
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportExportPage(fromKey: _fromKey, toKey: _toKey),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: '정산 마감일',
                  icon: const Icon(AppIcons.cycle),
                  onPressed: () => _editCycleStartDay(cycleStart),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InkPill(
                    label: '이번 달',
                    height: 38,
                    selected: _period == _Period.thisMonth,
                    onTap: _setThisMonth,
                  ),
                  InkPill(
                    label: '지난달',
                    height: 38,
                    selected: _period == _Period.lastMonth,
                    onTap: _setLastMonth,
                  ),
                  if (cycleStart != 1)
                    InkPill(
                      key: const ValueKey('cycle-chip'),
                      label: '$cycleStart일 마감',
                      height: 38,
                      selected: _period == _Period.cycle,
                      onTap: () => _setCycle(cycleStart),
                    ),
                ],
              ),
            ),
            // 기간 직접 고르기 — 작은 글자 버튼 두 개.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    key: const ValueKey('pick-from'),
                    icon: const Icon(AppIcons.calendar, size: 16),
                    label: Text(_fmt(_fromKey)),
                    style: _dateButtonStyle(c),
                    onPressed: () => _pickDate(isFrom: true),
                  ),
                  Text('~', style: dateStyle),
                  TextButton.icon(
                    key: const ValueKey('pick-to'),
                    icon: const Icon(AppIcons.calendar, size: 16),
                    label: Text(_fmt(_toKey)),
                    style: _dateButtonStyle(c),
                    onPressed: () => _pickDate(isFrom: false),
                  ),
                ],
              ),
            ),
            if (settlement == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _TotalBlock(settlement: settlement, range: _range),
              if (settlement.sites.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '이 기간에는 기록이 없어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted),
                  ),
                ),
              for (final s in settlement.sites)
                _SiteCard(settlement: s, site: siteById[s.siteId]),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  static ButtonStyle _dateButtonStyle(AppColors c) => TextButton.styleFrom(
    foregroundColor: c.muted,
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    textStyle: const TextStyle(
      fontFamily: AppFonts.body,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// 금액 한 줄: 왼쪽 이름(보조색), 오른쪽 값. [strong] 이면 실수령처럼 크게 +
/// 위에 잉크 선.
class _Line extends StatelessWidget {
  const _Line(
    this.label,
    this.value, {
    this.strong = false,
    this.red = false,
    this.valueKey,
    this.valueSize,
  });

  final String label;
  final String value;
  final bool strong;
  final bool red;
  final String? valueKey;
  final double? valueSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 필드는 널 승격이 안 돼 ValueKey<String?> 가 되어 버린다 — 지역 변수로.
    final keyName = valueKey;
    return Container(
      padding: EdgeInsets.only(top: strong ? 8 : 5),
      margin: EdgeInsets.only(top: strong ? 6 : 0),
      decoration: strong
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.text, width: 2)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: strong ? 15 : 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: strong ? c.text : c.muted,
              ),
            ),
          ),
          Text(
            value,
            key: keyName == null ? null : ValueKey(keyName),
            style: TextStyle(
              fontSize: valueSize ?? (strong ? 24 : 14),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: red ? c.red : c.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 기간 합계 — 카드 없이 종이 위에 바로.
class _TotalBlock extends StatelessWidget {
  const _TotalBlock({required this.settlement, required this.range});

  final PeriodSettlement settlement;
  final String Function(int from, int to) range;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = settlement;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '${range(s.fromKey, s.toKey)} · 근무 ${s.workedDays}일',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatGongsu(s.totalCenti),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: c.text,
                      ),
                    ),
                    TextSpan(
                      text: ' 공수',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (s.hasMoney) ...[
            _Line('세전 수입', formatWon(s.grossWon), valueKey: 'settle-gross'),
            if (!s.tax.isZero)
              _Line('세금 · 보험', '−${formatWon(s.tax.totalWon)}', red: true),
            _Line(
              '실수령',
              formatWon(s.netWon),
              strong: true,
              valueKey: 'settle-net',
            ),
            if (s.unpricedCenti > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '단가 없는 ${formatGongsu(s.unpricedCenti)}공수는 금액에서 제외',
                  style: TextStyle(fontSize: 12, color: c.red),
                ),
              ),
            if (!s.hasTaxConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '업체 수정에서 세금 방식을 고르면 공제가 계산돼요.',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// 업체별 카드 — 흰 면, 이름 + 세금 방식 칩, 항목별 줄, 실수령.
class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.settlement, required this.site});

  final SiteSettlement settlement;
  final Site? site;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = settlement;
    final name = s.siteId == null ? '업체 미지정' : (site?.name ?? '삭제된 업체');
    final t = s.tax;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
              ),
              if (s.siteId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.tint05,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    s.taxMode.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _Line('공수 · 근무일', '${formatGongsu(s.centi)} 공수 · ${s.workedDays}일'),
          if (s.hasMoney) ...[
            _Line('노무비 (공수 × 단가)', formatWon(s.laborWon)),
            if (s.allowanceWon > 0)
              _Line('가산 항목', '+${formatWon(s.allowanceWon)}'),
            if (s.deductionWon > 0)
              _Line('공제 항목', '−${formatWon(s.deductionWon)}', red: true),
            if (!t.isZero) ...[
              if (t.incomeTaxWon > 0)
                _Line('소득세', '−${formatWon(t.incomeTaxWon)}', red: true),
              if (t.localIncomeTaxWon > 0)
                _Line('지방소득세', '−${formatWon(t.localIncomeTaxWon)}', red: true),
              if (t.pensionWon > 0)
                _Line('국민연금', '−${formatWon(t.pensionWon)}', red: true),
              if (t.healthWon > 0)
                _Line('건강보험', '−${formatWon(t.healthWon)}', red: true),
              if (t.longTermCareWon > 0)
                _Line('장기요양', '−${formatWon(t.longTermCareWon)}', red: true),
              if (t.employmentWon > 0)
                _Line('고용보험', '−${formatWon(t.employmentWon)}', red: true),
            ],
            _Line('실수령', formatWon(s.netWon), strong: true, valueSize: 20),
            if (s.unpricedCenti > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '단가 없는 ${formatGongsu(s.unpricedCenti)}공수 제외',
                  style: TextStyle(fontSize: 12, color: c.red),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
