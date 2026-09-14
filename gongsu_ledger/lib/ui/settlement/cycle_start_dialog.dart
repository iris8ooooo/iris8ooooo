import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../state/db_providers.dart';

/// 정산 마감 주기 시작일 (1~28). 정산 화면과 설정 화면이 같이 쓴다.
/// 저장했으면 새 값을, 취소면 null 을 돌려준다.
Future<int?> showCycleStartDialog(
  BuildContext context,
  WidgetRef ref, {
  required int current,
}) async {
  var chosen = current;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('정산 마감일'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '현장 정산이 매월 1일이 아니라면 시작일을 정하세요.\n예: 21 → 전월 21일 ~ 당월 20일',
            ),
            const SizedBox(height: 12),
            DropdownButton<int>(
              key: const ValueKey('cycle-start-dropdown'),
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
  if (saved != true) return null;
  await ref
      .read(settingsRepoProvider)
      .setInt(SettingsRepository.keySettleCycleStartDay, chosen);
  return chosen;
}

/// 설정 줄에 보이는 문구.
String cycleStartLabel(int startDay) =>
    startDay == 1 ? '매월 1일 (달력 월 그대로)' : '매월 $startDay일 ~ 다음 달 ${startDay - 1}일';
