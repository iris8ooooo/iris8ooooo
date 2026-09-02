import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/site_repository.dart';
import '../../domain/date_key.dart';
import '../../domain/marker_palette.dart';
import '../../state/db_providers.dart';
import '../../state/site_providers.dart';
import '../common/won_format.dart';

/// 업체 추가/수정 + 단가 이력 관리.
class SiteEditPage extends ConsumerStatefulWidget {
  const SiteEditPage({super.key, this.site});

  /// null이면 새 업체.
  final Site? site;

  @override
  ConsumerState<SiteEditPage> createState() => _SiteEditPageState();
}

class _SiteEditPageState extends ConsumerState<SiteEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _initialRateController;
  late int _colorId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site?.name ?? '');
    _initialRateController = TextEditingController();
    _colorId = widget.site?.colorId ?? _suggestColor();
  }

  /// 새 업체는 기존 업체와 겹치지 않는 색을 기본 제안한다.
  int _suggestColor() {
    final used = (ref.read(sitesProvider).valueOrNull ?? const <Site>[])
        .map((s) => s.colorId)
        .toSet();
    for (final e in MarkerPalette.entries) {
      if (!used.contains(e.id)) return e.id;
    }
    return 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialRateController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final repo = ref.read(siteRepoProvider);
    try {
      if (widget.site == null) {
        await repo.create(
          name: _nameController.text,
          colorId: _colorId,
          dailyRateWon: parseWon(_initialRateController.text),
        );
      } else {
        await repo.update(
          id: widget.site!.id,
          name: _nameController.text,
          colorId: _colorId,
        );
      }
    } catch (e) {
      if (mounted) _showMessage('저장하지 못했어요. 입력을 확인해 주세요.');
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 단가 개정/수정 다이얼로그. [existing]이 있으면 그 이력을 수정.
  Future<void> _editRate({SiteRateHistory? existing}) async {
    final site = widget.site!;
    final today = DateTime.now();
    var effectiveDate = existing != null
        ? dateFromKey(existing.effectiveFromDateKey)
        : DateTime(today.year, today.month, today.day);
    final amountController = TextEditingController(
      text: existing == null ? '' : '${existing.dailyRateWon}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? '단가 변경' : '단가 이력 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('적용 시작일'),
                subtitle: Text(
                  '${effectiveDate.year}년 ${effectiveDate.month}월 ${effectiveDate.day}일부터',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    helpText: '이 날짜부터 새 단가 적용',
                  );
                  if (picked != null) {
                    setDialogState(() => effectiveDate = picked);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                autofocus: existing == null,
                keyboardType: TextInputType.number,
                inputFormatters: wonInputFormatters,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: '1공수 단가 (원)',
                  suffixText: '원',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 날짜 이전의 기록은 예전 단가 그대로 계산돼요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
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

    final amount = parseWon(amountController.text);
    if (amount == null) {
      _showMessage('단가 금액을 입력해 주세요.');
      return;
    }
    final repo = ref.read(siteRepoProvider);
    try {
      if (existing == null) {
        await repo.setRate(
          siteId: site.id,
          effectiveFromDateKey: dateKeyOf(effectiveDate),
          dailyRateWon: amount,
        );
      } else {
        await repo.updateRate(
          id: existing.id,
          effectiveFromDateKey: dateKeyOf(effectiveDate),
          dailyRateWon: amount,
        );
      }
    } catch (e) {
      if (mounted) _showMessage('단가를 저장하지 못했어요.');
    }
  }

  Future<void> _confirmDeleteRate(SiteRateHistory rate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단가 이력 삭제'),
        content: Text(
          '${_formatDateKey(rate.effectiveFromDateKey)}부터 ${formatWon(rate.dailyRateWon)} 이력을 삭제할까요?\n'
          '그 기간의 기록은 이전 단가로 계산돼요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(siteRepoProvider).deleteRate(rate.id);
    }
  }

  static String _formatDateKey(int key) {
    if (key <= initialRateEffectiveFromDateKey) return '처음';
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.site == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '업체 추가' : '업체 수정'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            maxLength: 30,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: '업체(현장) 이름',
              hintText: '예: ○○건설 A현장',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text('색상 (달력 표시)', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in MarkerPalette.entries)
                InkWell(
                  key: ValueKey('site-color-${entry.id}'),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _colorId = entry.id),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MarkerPalette.colorOf(
                        entry.id,
                        brightness: Theme.of(context).brightness,
                      ),
                      border: _colorId == entry.id
                          ? Border.all(color: scheme.onSurface, width: 3)
                          : null,
                    ),
                    child: _colorId == entry.id
                        ? Icon(
                            Icons.check,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (isNew) ...[
            TextField(
              controller: _initialRateController,
              keyboardType: TextInputType.number,
              inputFormatters: wonInputFormatters,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: '1공수 단가 (원) — 나중에 넣어도 돼요',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '단가가 오르면 업체 수정 화면에서 "단가 변경"으로 적용 시작일을 정해 추가하세요. 이전 기록은 예전 단가로 유지됩니다.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ] else
            _RateHistorySection(
              siteId: widget.site!.id,
              onAdd: () => _editRate(),
              onEdit: (r) => _editRate(existing: r),
              onDelete: _confirmDeleteRate,
              formatDateKey: _formatDateKey,
            ),
        ],
      ),
    );
  }
}

class _RateHistorySection extends ConsumerWidget {
  const _RateHistorySection({
    required this.siteId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.formatDateKey,
  });

  final int siteId;
  final VoidCallback onAdd;
  final void Function(SiteRateHistory) onEdit;
  final void Function(SiteRateHistory) onDelete;
  final String Function(int) formatDateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final rates =
        ref.watch(siteRatesProvider(siteId)).valueOrNull ??
        const <SiteRateHistory>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '단가 이력',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('add-rate'),
              icon: const Icon(Icons.add),
              label: const Text('단가 변경'),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '아직 단가가 없어요. "단가 변경"으로 추가하면 예상 수입이 계산돼요.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final rate in rates)
            ListTile(
              key: ValueKey('rate-${rate.id}'),
              contentPadding: const EdgeInsets.only(left: 4),
              title: Text(
                formatWon(rate.dailyRateWon),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text('${formatDateKey(rate.effectiveFromDateKey)}부터'),
              onTap: () => onEdit(rate),
              trailing: IconButton(
                tooltip: '이력 삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(rate),
              ),
            ),
      ],
    );
  }
}
