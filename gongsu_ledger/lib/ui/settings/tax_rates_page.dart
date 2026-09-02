import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../domain/percent_format.dart';
import '../../domain/tax_engine.dart';
import '../../domain/tax_rates.dart';
import '../../state/db_providers.dart';
import '../../state/tax_providers.dart';
import '../common/won_format.dart';

/// 세율·보험료율 설정. 연도별 기본 테이블을 보여주고 항목별로 직접 고칠 수
/// 있다 (경쟁앱 불만: 요율 갱신이 늦음). 끝전 처리 방식도 여기서.
class TaxRatesPage extends ConsumerStatefulWidget {
  const TaxRatesPage({super.key});

  @override
  ConsumerState<TaxRatesPage> createState() => _TaxRatesPageState();
}

class _TaxRatesPageState extends ConsumerState<TaxRatesPage> {
  late int _year = DateTime.now().year;

  Future<void> _editField(TaxRateTable table, TaxRateKey key) async {
    final isPercent = key.kind == TaxRateFieldKind.percent;
    final controller = TextEditingController(
      text: isPercent
          ? formatPercentPer100k(table.valueOf(key))
          : '${table.valueOf(key)}',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(key.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              key.description,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('rate-input'),
              controller: controller,
              autofocus: true,
              keyboardType: isPercent
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: isPercent ? null : wonInputFormatters,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                suffixText: isPercent ? '%' : '원',
                border: const OutlineInputBorder(),
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
    );
    if (saved != true || !mounted) return;
    final value = isPercent
        ? parsePercentPer100k(controller.text)
        : parseWon(controller.text);
    if (value == null) {
      _showMessage(
        isPercent ? '0~100 사이의 퍼센트를 소수 3자리까지 입력해 주세요.' : '금액을 숫자로 입력해 주세요.',
      );
      return;
    }
    final updated = table.withValue(key, value);
    await ref
        .read(settingsRepoProvider)
        .setTaxRatesOverride(_year, updated.toJson());
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$_year년 요율 초기화'),
        content: const Text('직접 고친 값을 모두 지우고 앱 기본값으로 되돌릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsRepoProvider).clearTaxRatesOverride(_year);
    }
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final table =
        ref.watch(taxRatesProvider(_year)).valueOrNull ??
        defaultTaxRateTable(_year);
    final defaults = defaultTaxRateTable(_year);
    final rounding =
        ref.watch(taxRoundingProvider).valueOrNull ?? TaxRounding.floor10;
    final isCustomized = !table.sameValuesAs(defaults);

    return Scaffold(
      appBar: AppBar(
        title: const Text('세금 · 요율 설정'),
        actions: [
          if (isCustomized)
            TextButton(onPressed: _reset, child: const Text('초기화')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '끝전 처리',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TaxRounding>(
                    segments: [
                      for (final r in TaxRounding.values)
                        ButtonSegment(value: r, label: Text(r.label)),
                    ],
                    selected: {rounding},
                    onSelectionChanged: (s) => ref
                        .read(settingsRepoProvider)
                        .set(SettingsRepository.keyTaxRounding, s.first.code),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '원천징수 실무는 세금·보험료의 10원 미만을 버립니다. 명세서와 다르면 "원 단위 그대로"로 바꿔 보세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '$_year년 요율',
                key: const ValueKey('rates-year'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              isCustomized
                  ? '직접 고친 값이 있어요 (기본값과 다른 항목에 표시).'
                  : '근로자 부담분 기준 앱 기본값입니다. 항목을 탭하면 고칠 수 있어요.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          for (final key in TaxRateKey.values)
            ListTile(
              key: ValueKey('rate-${key.code}'),
              title: Text(key.label),
              subtitle: Text(
                key.description,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (table.valueOf(key) != defaults.valueOf(key))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.edit, size: 16, color: scheme.primary),
                    ),
                  Text(
                    key.kind == TaxRateFieldKind.percent
                        ? '${formatPercentPer100k(table.valueOf(key))}%'
                        : formatWon(table.valueOf(key)),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              onTap: () => _editField(table, key),
            ),
        ],
      ),
    );
  }
}
