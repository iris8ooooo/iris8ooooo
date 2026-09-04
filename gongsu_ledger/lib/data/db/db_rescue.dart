import 'dart:io';

import 'package:path/path.dart' as p;

/// 열리지 않는 DB 파일을 "옆으로 치워 두는" 구조 경로. 절대 지우지 않는다 —
/// 파일은 `gongsu.db.corrupt_<millis>.bak`(+ -wal/-shm) 로 남고, 앱은 새 DB로
/// 시작한 뒤 최근 자동 스냅샷을 병합해 기록을 되살린다.
///
/// 반환값: 치워 둔 파일들의 경로 (없었으면 빈 목록).
Future<List<String>> quarantineDatabaseFiles(
  Directory dir, {
  String baseName = 'gongsu.db',
  int? nowMillis,
}) async {
  final stamp = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
  final moved = <String>[];
  for (final suffix in const ['', '-wal', '-shm']) {
    final src = File(p.join(dir.path, '$baseName$suffix'));
    if (!src.existsSync()) continue;
    final dst = File(p.join(dir.path, '$baseName.corrupt_$stamp$suffix.bak'));
    src.renameSync(dst.path);
    moved.add(dst.path);
  }
  return moved;
}
