import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/marker_palette.dart';
import '../../state/db_providers.dart';
import '../../state/preset_providers.dart';
import 'preset_edit_page.dart';

/// 프리셋 관리: 추가 / 수정 / 순서 변경 / 보관(삭제).
class PresetListPage extends ConsumerWidget {
  const PresetListPage({super.key});

  Future<void> _confirmArchive(
      BuildContext context, WidgetRef ref, Preset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\'${preset.name}\' 삭제'),
        content: const Text('이 프리셋으로 입력한 과거 기록은 그대로 유지됩니다.'),
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
      await ref.read(presetRepoProvider).archive(preset.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetsProvider);
    final presets = presetsAsync.valueOrNull ?? const <Preset>[];

    return Scaffold(
      appBar: AppBar(title: const Text('프리셋 관리')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('프리셋 추가'),
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PresetEditPage())),
      ),
      body: presets.isEmpty && presetsAsync.hasValue
          ? const Center(child: Text('아래 버튼으로 프리셋을 추가하세요'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: presets.length,
              onReorderItem: (oldIndex, newIndex) {
                final ids = presets.map((p) => p.id).toList();
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                ref.read(presetRepoProvider).reorder(ids);
              },
              itemBuilder: (context, index) {
                final preset = presets[index];
                return ListTile(
                  key: ValueKey('preset-tile-${preset.id}'),
                  leading: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MarkerPalette.colorOf(preset.colorId,
                          brightness: Theme.of(context).brightness),
                    ),
                  ),
                  title: Text(preset.name),
                  subtitle: Text('${formatGongsu(preset.centiGongsu)} 공수'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PresetEditPage(preset: preset))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _confirmArchive(context, ref, preset),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
