import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/marker_palette.dart';
import '../../state/db_providers.dart';
import '../common/gongsu_keypad.dart';

/// 프리셋 추가/수정: 이름 + 공수값(자체 키패드) + 팔레트 색.
class PresetEditPage extends ConsumerStatefulWidget {
  const PresetEditPage({super.key, this.preset});

  /// null이면 새 프리셋.
  final Preset? preset;

  @override
  ConsumerState<PresetEditPage> createState() => _PresetEditPageState();
}

class _PresetEditPageState extends ConsumerState<PresetEditPage> {
  late final TextEditingController _nameController;
  late int? _centi;
  late int _colorId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _centi = widget.preset?.centiGongsu;
    _colorId = widget.preset?.colorId ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickValue() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: GongsuKeypad(
          initialCenti: _centi,
          saveLabel: '확인',
          onSave: (centi) {
            setState(() => _centi = centi);
            Navigator.of(sheetContext).pop();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _centi != null;

  Future<void> _save() async {
    final repo = ref.read(presetRepoProvider);
    final name = _nameController.text;
    try {
      if (widget.preset == null) {
        await repo.create(
            name: name, centiGongsu: _centi!, colorId: _colorId);
      } else {
        await repo.update(
            id: widget.preset!.id,
            name: name,
            centiGongsu: _centi!,
            colorId: _colorId);
      }
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('저장하지 못했어요. 입력을 확인해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.preset == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '프리셋 추가' : '프리셋 수정'),
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
            maxLength: 20,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: '이름 (예: 1공수, E잔업, 야간)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: scheme.outline),
            ),
            title: const Text('공수값'),
            subtitle: Text(
              _centi == null ? '탭해서 입력' : '${formatGongsu(_centi!)} 공수',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _centi == null ? scheme.onSurfaceVariant : null,
              ),
            ),
            trailing: const Icon(Icons.edit),
            onTap: _pickValue,
          ),
          const SizedBox(height: 16),
          Text('색상', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in MarkerPalette.entries)
                InkWell(
                  key: ValueKey('color-${entry.id}'),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _colorId = entry.id),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MarkerPalette.colorOf(entry.id,
                          brightness: Theme.of(context).brightness),
                      border: _colorId == entry.id
                          ? Border.all(color: scheme.onSurface, width: 3)
                          : null,
                    ),
                    child: _colorId == entry.id
                        ? Icon(Icons.check,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.black
                                : Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '휴무 프리셋은 공수값을 0으로 만드세요.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
