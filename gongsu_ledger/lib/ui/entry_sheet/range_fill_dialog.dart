import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/range_fill.dart';
import '../app_theme.dart';
import '../common/app_icons.dart';
import '../common/choice_chip_row.dart';

typedef RangeFillInput = ({int toKey, Preset preset, bool skipRestDays});

const List<String> _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

String _label(int key) {
  final d = dateFromKey(key);
  return '${d.month}월 ${d.day}일 (${_weekdayNames[d.weekday - 1]})';
}

/// 연속 채우기 다이얼로그 — 시작일은 시트의 날짜, 종료일·프리셋·쉬는 날
/// 제외를 고른다. [occupied]는 이미 기록이 있는 날짜(미리 보기용).
Future<RangeFillInput?> showRangeFillDialog(
  BuildContext context, {
  required int fromKey,
  required List<Preset> presets,
  required Set<int> occupied,
}) {
  var toKey = monthEndKeyOf(fromKey);
  if (toKey == fromKey) toKey = addDaysToKey(fromKey, 6);
  var preset = presets.first;
  var skipRestDays = true;

  return showDialog<RangeFillInput>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final c = dialogContext.colors;
        final plan = planRangeFill(
          fromKey: fromKey,
          toKey: toKey,
          skipRestDays: skipRestDays,
          occupied: occupied,
        );
        final small = TextStyle(fontSize: 13, color: c.muted);

        Future<void> pickEnd() async {
          final picked = await showDatePicker(
            context: dialogContext,
            initialDate: dateFromKey(toKey),
            firstDate: dateFromKey(fromKey),
            lastDate: dateFromKey(addDaysToKey(fromKey, maxRangeFillDays - 1)),
            helpText: '마지막 날',
          );
          if (picked == null) return;
          setDialogState(() => toKey = dateKeyOf(picked));
        }

        return AlertDialog(
          title: const Text('연속 채우기'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${_label(fromKey)}부터', style: small),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  key: const ValueKey('range-end'),
                  icon: const Icon(AppIcons.calendar),
                  label: Text('${_label(toKey)}까지'),
                  onPressed: pickEnd,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      key: const ValueKey('range-week'),
                      label: const Text('일주일'),
                      onPressed: () => setDialogState(
                        () => toKey = addDaysToKey(fromKey, 6),
                      ),
                    ),
                    ActionChip(
                      key: const ValueKey('range-month-end'),
                      label: const Text('이 달 말까지'),
                      onPressed: () =>
                          setDialogState(() => toKey = monthEndKeyOf(fromKey)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('공수', style: small),
                const SizedBox(height: 6),
                ChoiceChipRow<Preset>(
                  options: presets,
                  selected: preset,
                  keyOf: (p) => 'range-preset-${p.id}',
                  labelOf: (p) => p.name == formatGongsu(p.centiGongsu)
                      ? p.name
                      : '${p.name} ${formatGongsu(p.centiGongsu)}',
                  onSelected: (p) => setDialogState(() => preset = p),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  key: const ValueKey('range-skip-rest'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('일요일·공휴일은 건너뛰기'),
                  value: skipRestDays,
                  onChanged: (v) => setDialogState(() => skipRestDays = v),
                ),
                Text(
                  plan.dateKeys.isEmpty
                      ? '넣을 날이 없어요.'
                      : '${plan.dateKeys.length}일에 ${preset.name} 기록이 들어가요.'
                            '${plan.skippedOccupied > 0 ? ' 이미 기록이 있는 ${plan.skippedOccupied}일은 그대로 둬요.' : ''}',
                  key: const ValueKey('range-preview'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
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
              key: const ValueKey('range-fill-confirm'),
              onPressed: plan.dateKeys.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop((
                      toKey: toKey,
                      preset: preset,
                      skipRestDays: skipRestDays,
                    )),
              child: const Text('채우기'),
            ),
          ],
        );
      },
    ),
  );
}
