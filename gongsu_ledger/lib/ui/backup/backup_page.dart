import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_codec.dart';
import '../../data/backup/backup_text_codec.dart';
import '../../data/backup/snapshot_service.dart';
import '../../domain/date_key.dart';
import '../../state/backup_providers.dart';
import '../../state/db_providers.dart';

/// 백업/복원 — 절대 원칙 4의 3중 안전장치.
/// (a) 자동 로컬 스냅샷 7일 (b) 텍스트 백업(복사→카톡 나에게 보내기→붙여넣기)
/// (c) JSON 파일 내보내기/가져오기. 모든 복원은 병합 전용이라 기존 기록을
/// 지우지 않는다.
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

  String _todayStamp() => '${dateKeyOf(DateTime.now())}';

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── 텍스트 백업 ──────────────────────────────────────────
  Future<void> _copyText() => _run(() async {
    try {
      final json = await exportBackupJson(ref.read(databaseProvider));
      await Clipboard.setData(ClipboardData(text: encodeBackupText(json)));
      _showMessage(
        '복사 완료',
        '백업 텍스트가 복사되었어요.\n카카오톡 "나에게 보내기"나 메모 앱에 붙여넣어 두세요.\n'
            '새 휴대폰에서는 그 텍스트를 이 화면의 "붙여넣어 복원"에 넣으면 됩니다.',
      );
    } catch (e) {
      _showMessage('실패', '백업 텍스트를 만들지 못했어요. 다시 시도해 주세요.');
    }
  });

  Future<void> _shareText() => _run(() async {
    try {
      final json = await exportBackupJson(ref.read(databaseProvider));
      await ref
          .read(shareServiceProvider)
          .shareText(
            encodeBackupText(json),
            subject: '공수장부 백업 ${_todayStamp()}',
          );
    } catch (e) {
      _showMessage('실패', '공유 창을 열지 못했어요.');
    }
  });

  // ── 파일 백업 ────────────────────────────────────────────
  Future<void> _exportFile() => _run(() async {
    try {
      final json = await exportBackupJson(ref.read(databaseProvider));
      await ref
          .read(shareServiceProvider)
          .shareBytes(
            Uint8List.fromList(utf8.encode(json)),
            fileName: 'gongsu-backup-${_todayStamp()}.json',
            mimeType: 'application/json',
          );
    } catch (e) {
      _showMessage('실패', '파일을 내보내지 못했어요.');
    }
  });

  Future<void> _importFile() => _run(() async {
    final String? text;
    try {
      text = await ref.read(backupFileServiceProvider).pickBackupText();
    } catch (e) {
      _showMessage('실패', '파일을 열지 못했어요.');
      return;
    }
    if (text == null) return; // 취소
    await _importText(text, source: '파일');
  });

  // ── 공통 복원 ────────────────────────────────────────────
  Future<void> _importPasted() => _run(() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      _showMessage('안내', '먼저 백업 텍스트를 붙여넣어 주세요.');
      return;
    }
    await _importText(text, source: '붙여넣은 텍스트');
  });

  Future<void> _importText(String text, {required String source}) async {
    final String json;
    try {
      json = decodeBackupText(text);
    } on BackupFormatError {
      _showMessage('복원 불가', '올바른 공수장부 백업이 아니에요.\n복사한 내용 전체를 그대로 넣었는지 확인해 주세요.');
      return;
    }
    final confirmed = await _confirm(
      '데이터 병합 복원',
      '$source의 백업을 지금 데이터에 병합합니다.\n같은 기록은 더 최신 것이 남고, 기존 기록이 지워지는 일은 없어요.',
      '복원',
    );
    if (confirmed != true || !mounted) return;
    await _applyImport(json);
  }

  Future<void> _applyImport(String json) async {
    try {
      final result = await importBackupJson(ref.read(databaseProvider), json);
      if (!mounted) return;
      _importController.clear();
      final skippedNote = result.skipped > 0
          ? '\n손상된 행 ${result.skipped}건은 건너뛰었어요.'
          : '';
      _showMessage(
        '복원 완료',
        '추가 ${result.inserted}건, 갱신 ${result.updated}건을 반영했어요.$skippedNote',
      );
    } on BackupTooNew {
      _showMessage(
        '복원 불가',
        '이 백업은 더 새로운 버전의 앱에서 만든 것이에요.\n앱을 업데이트한 뒤 다시 복원해 주세요.',
      );
    } on BackupFormatError {
      _showMessage('복원 불가', '올바른 공수장부 백업 데이터가 아니에요.');
    } catch (e) {
      _showMessage('실패', '복원 중 문제가 생겼어요. 데이터는 바뀌지 않았어요.');
    }
  }

  // ── 스냅샷 ───────────────────────────────────────────────
  Future<void> _snapshotNow() => _run(() async {
    try {
      await ref
          .read(snapshotServiceProvider)
          .writeSnapshot(ref.read(databaseProvider), dateKeyOf(DateTime.now()));
      ref.invalidate(snapshotsProvider);
    } catch (e) {
      _showMessage('실패', '스냅샷을 만들지 못했어요.');
    }
  });

  Future<void> _restoreSnapshot(SnapshotInfo info) => _run(() async {
    final confirmed = await _confirm(
      '${_formatDate(info.dateKey)} 스냅샷 복원',
      '그날 저장된 자동 백업을 지금 데이터에 병합합니다.\n그 뒤에 입력한 기록은 그대로 남아요.',
      '복원',
    );
    if (confirmed != true || !mounted) return;
    try {
      final json = await ref.read(snapshotServiceProvider).readJson(info);
      await _applyImport(json);
    } catch (e) {
      _showMessage('실패', '스냅샷을 읽지 못했어요.');
    }
  });

  static String _formatDate(int key) {
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  static String _formatSize(int bytes) =>
      bytes < 1024 ? '$bytes B' : '${(bytes / 1024).round()} KB';

  Future<bool?> _confirm(String title, String body, String action) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      );

  void _showMessage(String title, String body) {
    if (!mounted) return;
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
    final snapshots = ref.watch(snapshotsProvider);
    final hint = TextStyle(color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: const Text('백업 / 복원')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: '텍스트 백업 (추천)',
            children: [
              Text(
                '전체 기록을 짧은 텍스트로 만들어요. 카카오톡 "나에게 보내기"에 붙여넣어 두면 '
                '휴대폰을 바꿔도 복원할 수 있어요.',
                style: hint,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('copy-text-backup'),
                icon: const Icon(Icons.copy),
                label: const Text('백업 텍스트 복사'),
                onPressed: _busy ? null : _copyText,
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('share-text-backup'),
                icon: const Icon(Icons.share),
                label: const Text('바로 공유 (카톡 등)'),
                onPressed: _busy ? null : _shareText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: '붙여넣어 복원',
            children: [
              Text(
                '복사해 둔 백업 텍스트를 붙여넣고 복원을 누르세요. 병합 방식이라 기존 기록은 지워지지 않아요.',
                style: hint,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('import-text'),
                controller: _importController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'GSJB1: 으로 시작하는 백업 텍스트',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('restore-button'),
                icon: const Icon(Icons.restore),
                label: const Text('병합 복원'),
                onPressed: _busy ? null : _importPasted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: '파일 백업',
            children: [
              Text(
                'JSON 파일로 저장하거나(파일 앱·구글 드라이브 등), 저장해 둔 파일을 골라 복원해요.',
                style: hint,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('export-file'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('파일 내보내기'),
                      onPressed: _busy ? null : _exportFile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('import-file'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('파일 가져오기'),
                      onPressed: _busy ? null : _importFile,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: '자동 스냅샷 (최근 7일)',
            children: [
              Text(
                '앱을 열거나 닫을 때 그날의 백업을 기기 안에 자동으로 남겨요. 실수로 지웠을 때 여기서 되돌립니다.',
                style: hint,
              ),
              const SizedBox(height: 8),
              snapshots.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('스냅샷 폴더를 열 수 없어요.', style: hint),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('아직 스냅샷이 없어요.', style: hint),
                      )
                    : Column(
                        children: [
                          for (final s in list)
                            ListTile(
                              key: ValueKey('snapshot-tile-${s.dateKey}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history),
                              title: Text(_formatDate(s.dateKey)),
                              subtitle: Text(_formatSize(s.sizeBytes)),
                              trailing: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _restoreSnapshot(s),
                                child: const Text('복원'),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const ValueKey('snapshot-now'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('지금 스냅샷 만들기'),
                onPressed: _busy ? null : _snapshotNow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      );
}
