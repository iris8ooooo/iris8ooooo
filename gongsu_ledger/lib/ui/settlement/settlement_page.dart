import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pro_limits.dart';
import '../pro/pro_gate.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/settlement.dart';
import '../../state/db_providers.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';
import '../common/won_format.dart';
import '../export/report_export_page.dart';

/// 기간 지정 정산 — 월초 기준이 아닌 임의 기간(예: 전월 21일~당월 20일 마감
/// 현장)의 업체별 공수·세전·공제·실수령.
class SettlementPage extends ConsumerStatefulWidget {
  const SettlementPage({super.key});

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends ConsumerState<SettlementPage> {
  late int _fromKey;
  late int _toKey;

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
      _fromKey = dateKeyOf(DateTime(now.year, now.month, 1));
      _toKey = dateKeyOf(DateTime(now.year, now.month + 1, 0));
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
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
    var chosen = current;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('마감 주기 시작일'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '현장 정산이 매월 1일이 아니라면 시작일을 정하세요.\n예: 21 → 전월 21일 ~ 당월 20일',
              ),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: chosen,
                isExpanded: true,
                items: [
                  for (var d = 1; d <= 28; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(d == 1 ? '1일 (달력 월 그대로)' : '$d일'),
                    ),
                ],
                onChanged: (v) => setDialogState(() => chosen = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    await ref
        .read(settingsRepoProvider)
        .setInt(SettingsRepository.keySettleCycleStartDay, chosen);
    _setCycle(chosen);
  }

  static String _fmt(int key) {
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cycleStart = ref.watch(settleCycleStartDayProvider).valueOrNull ?? 1;
    final settlement = ref.watch(
      periodSettlementProvider(periodKey(_fromKey, _toKey)),
    );
    final siteById = ref.watch(siteByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산'),
        actions: [
          IconButton(
            key: const ValueKey('export-pdf'),
            tooltip: '공수 확인서 PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              // 공수 확인서 PDF 는 프로 기능.
              if (!await ensurePro(context, ref, feature: ProFeature.pdf)) {
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
            tooltip: '마감 주기 설정',
            icon: const Icon(Icons.event_repeat),
            onPressed: () => _editCycleStartDay(cycleStart),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('이번 달'), onPressed: _setThisMonth),
              ActionChip(label: const Text('지난달'), onPressed: _setLastMonth),
              if (cycleStart != 1)
                ActionChip(
                  key: const ValueKey('cycle-chip'),
                  label: Text('마감 주기 ($cycleStart일~)'),
                  onPressed: () => _setCycle(cycleStart),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('pick-from'),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_fmt(_fromKey)),
                  onPressed: () => _pickDate(isFrom: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('~'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('pick-to'),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_fmt(_toKey)),
                  onPressed: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (settlement == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _TotalCard(settlement: settlement),
            const SizedBox(height: 8),
            if (settlement.sites.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '이 기간에는 기록이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            for (final s in settlement.sites)
              _SiteCard(settlement: s, site: siteById[s.siteId]),
          ],
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.settlement});

  final PeriodSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = settlement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_SettlementPageState._fmt(s.fromKey)} ~ ${_SettlementPageState._fmt(s.toKey)}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            _line('총 공수', '${formatGongsu(s.totalCenti)} 공수', big: true),
            _line('근무일', '${s.workedDays}일'),
            if (s.hasMoney) ...[
              const Divider(height: 16),
              _line('세전 수입', formatWon(s.grossWon), key: 'settle-gross'),
              if (!s.tax.isZero)
                _line('세금·보험 공제', '−${formatWon(s.tax.totalWon)}'),
              _line('실수령', formatWon(s.netWon), big: true, key: 'settle-net'),
              if (s.unpricedCenti > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '단가 없는 ${formatGongsu(s.unpricedCenti)}공수는 금액에서 제외',
                    style: TextStyle(fontSize: 13, color: scheme.error),
                  ),
                ),
              if (!s.hasTaxConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '업체 수정에서 세금 방식을 고르면 공제가 계산돼요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _line(String label, String value, {bool big = false, String? key}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: big ? 17 : 15)),
        ),
        Text(
          value,
          key: key == null ? null : ValueKey(key),
          style: TextStyle(
            fontSize: big ? 22 : 16,
            fontWeight: big ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.settlement, required this.site});

  final SiteSettlement settlement;
  final Site? site;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = settlement;
    final name = s.siteId == null ? '업체 미지정' : (site?.name ?? '삭제된 업체');
    final t = s.tax;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  s.taxMode.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _line('공수 / 근무일', '${formatGongsu(s.centi)} 공수 · ${s.workedDays}일'),
            if (s.hasMoney) ...[
              _line('노무비 (공수 × 단가)', formatWon(s.laborWon)),
              if (s.allowanceWon > 0)
                _line('가산 항목', '+${formatWon(s.allowanceWon)}'),
              if (s.deductionWon > 0)
                _line('공제 항목', '−${formatWon(s.deductionWon)}'),
              _line('세전', formatWon(s.grossWon)),
              if (!t.isZero) ...[
                const Divider(height: 12),
                if (t.incomeTaxWon > 0)
                  _line('소득세', '−${formatWon(t.incomeTaxWon)}'),
                if (t.localIncomeTaxWon > 0)
                  _line('지방소득세', '−${formatWon(t.localIncomeTaxWon)}'),
                if (t.pensionWon > 0)
                  _line('국민연금', '−${formatWon(t.pensionWon)}'),
                if (t.healthWon > 0)
                  _line('건강보험', '−${formatWon(t.healthWon)}'),
                if (t.longTermCareWon > 0)
                  _line('장기요양', '−${formatWon(t.longTermCareWon)}'),
                if (t.employmentWon > 0)
                  _line('고용보험', '−${formatWon(t.employmentWon)}'),
              ],
              _line('실수령', formatWon(s.netWon), big: true),
              if (s.unpricedCenti > 0)
                Text(
                  '단가 없는 ${formatGongsu(s.unpricedCenti)}공수 제외',
                  style: TextStyle(fontSize: 13, color: scheme.error),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
