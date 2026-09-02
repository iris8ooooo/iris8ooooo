import 'package:flutter/material.dart';

import '../../data/repositories/day_item_repository.dart';
import '../common/won_format.dart';

typedef ExtraItemInput = ({
  ExtraItemKind kind,
  String label,
  int amountWon,
  bool isTaxable,
});

/// 부가항목 추가 다이얼로그. 가산/공제 선택 → 자주 쓰는 이름 칩 → 금액.
Future<ExtraItemInput?> showExtraItemDialog(BuildContext context) {
  var kind = ExtraItemKind.allowance;
  var isTaxable = false;
  final labelController = TextEditingController();
  final amountController = TextEditingController();

  return showDialog<ExtraItemInput>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final quick = kind == ExtraItemKind.deduction
            ? deductionQuickLabels
            : allowanceQuickLabels;
        return AlertDialog(
          title: const Text('부가항목 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ExtraItemKind>(
                  segments: const [
                    ButtonSegment(
                      value: ExtraItemKind.allowance,
                      label: Text('가산 (+)'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                    ButtonSegment(
                      value: ExtraItemKind.deduction,
                      label: Text('공제 (−)'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (s) =>
                      setDialogState(() => kind = s.first),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final q in quick)
                      ActionChip(
                        key: ValueKey('quick-$q'),
                        label: Text(q),
                        onPressed: () =>
                            setDialogState(() => labelController.text = q),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: labelController,
                  maxLength: 20,
                  style: const TextStyle(fontSize: 17),
                  decoration: const InputDecoration(
                    labelText: '항목 이름',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                TextField(
                  key: const ValueKey('extra-amount'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: wonInputFormatters,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(
                    labelText: '금액',
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (kind == ExtraItemKind.allowance)
                  SwitchListTile(
                    key: const ValueKey('extra-taxable'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('세금 계산에 포함 (과세)'),
                    subtitle: const Text('식비·일비는 보통 비과세라 꺼 둡니다'),
                    value: isTaxable,
                    onChanged: (v) => setDialogState(() => isTaxable = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed:
                  labelController.text.trim().isEmpty ||
                      parseWon(amountController.text) == null
                  ? null
                  : () => Navigator.of(dialogContext).pop((
                      kind: kind,
                      label: labelController.text,
                      amountWon: parseWon(amountController.text)!,
                      isTaxable: kind == ExtraItemKind.allowance && isTaxable,
                    )),
              child: const Text('추가'),
            ),
          ],
        );
      },
    ),
  );
}
