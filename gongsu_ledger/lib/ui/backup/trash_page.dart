import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../state/db_providers.dart';
import '../../state/site_providers.dart';
import '../../state/trash_providers.dart';
import '../common/won_format.dart';

/// 삭제된 기록 — soft delete 된 공수·부가항목을 되살린다.
///
/// 절대 원칙 4(데이터 유실 = 사형): 지운 기록은 물리 삭제되지 않으므로
/// 실행 취소를 놓쳤어도 여기서 언제든 되돌릴 수 있다.
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  static String _date(int key) {
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  static String _when(int? millis) {
    if (millis == null) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} 삭제';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(deletedEntriesProvider).valueOrNull ?? const [];
    final items = ref.watch(deletedItemsProvider).valueOrNull ?? const [];
    final siteById = ref.watch(siteByIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('삭제된 기록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '지운 기록은 바로 사라지지 않고 여기 남아요. "되살리기"를 누르면 달력으로 돌아갑니다.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty && items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '삭제된 기록이 없어요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          for (final e in entries)
            ListTile(
              key: ValueKey('trash-entry-${e.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(
                '${_date(e.dateKey)} · '
                '${e.labelSnapshot.isEmpty ? '' : '${e.labelSnapshot} '}'
                '${formatGongsu(e.centiGongsu)}공수',
              ),
              subtitle: Text(
                [
                  if (e.siteId != null && siteById[e.siteId] != null)
                    siteById[e.siteId]!.name,
                  _when(e.deletedAtMillis),
                ].join(' · '),
              ),
              trailing: TextButton(
                onPressed: () => ref.read(workEntryRepoProvider).restore(e.id),
                child: const Text('되살리기'),
              ),
            ),
          for (final it in items)
            ListTile(
              key: ValueKey('trash-item-${it.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(
                '${_date(it.dateKey)} · ${it.label} ${formatWon(it.amountWon)}',
              ),
              subtitle: Text(_when(it.deletedAtMillis)),
              trailing: TextButton(
                onPressed: () => ref.read(dayItemRepoProvider).restore(it.id),
                child: const Text('되살리기'),
              ),
            ),
        ],
      ),
    );
  }
}
