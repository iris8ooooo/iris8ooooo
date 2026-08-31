import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_codec.dart';
import '../../state/db_providers.dart';

/// 간이 백업/복원 (M1 안전망). M4에서 자동 스냅샷·파일 내보내기로 확장된다.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final TextEditingController _importController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = await exportBackupJson(ref.read(databaseProvider));
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        _showMessage('복사 완료',
            '전체 데이터가 복사되었어요.\n카카오톡 "나에게 보내기"나 메모장에 붙여넣어 보관하세요.');
      }
    } catch (e) {
      if (mounted) _showMessage('실패', '내보내기에 실패했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showMessage('안내', '먼저 백업 데이터를 붙여넣어 주세요.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 병합 복원'),
        content: const Text('붙여넣은 백업을 지금 데이터에 병합합니다.\n'
            '같은 기록은 더 최신 것이 남고, 기존 기록이 지워지는 일은 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result =
          await importBackupJson(ref.read(databaseProvider), text);
      if (mounted) {
        _importController.clear();
        _showMessage('복원 완료',
            '추가 ${result.inserted}건, 갱신 ${result.updated}건을 반영했어요.');
      }
    } on BackupTooNew {
      if (mounted) {
        _showMessage('복원 불가', '이 백업은 더 새로운 버전의 앱에서 만든 것이에요.\n'
            '앱을 업데이트한 뒤 다시 복원해 주세요.');
      }
    } on BackupFormatError {
      if (mounted) {
        _showMessage('복원 불가', '올바른 공수장부 백업 데이터가 아니에요.\n'
            '복사한 내용 전체를 그대로 붙여넣었는지 확인해 주세요.');
      }
    } catch (e) {
      if (mounted) _showMessage('실패', '복원 중 문제가 생겼어요. 데이터는 바뀌지 않았어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    return Scaffold(
      appBar: AppBar(title: const Text('백업 / 복원')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('내보내기',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    '전체 기록을 텍스트로 복사해요. 카카오톡 "나에게 보내기"에 붙여넣어 두면 '
                    '휴대폰을 바꿔도 복원할 수 있어요.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('전체 데이터 복사'),
                    onPressed: _busy ? null : _export,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('가져오기',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    '예전에 복사해 둔 백업 텍스트를 붙여넣고 복원을 누르세요. '
                    '병합 방식이라 기존 기록은 지워지지 않아요.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _importController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '여기에 백업 텍스트 붙여넣기',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('병합 복원'),
                    onPressed: _busy ? null : _import,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
