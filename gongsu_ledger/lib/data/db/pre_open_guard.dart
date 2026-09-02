import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sq;

/// 구버전 앱이 신버전 DB를 만난 상황 (구버전 APK 재설치 등).
/// 절대 열지 않고, 파괴적 재생성도 하지 않는다 — UI는 업데이트 안내를 띄운다.
class DowngradeDetected implements Exception {
  DowngradeDetected({required this.dbVersion, required this.codeVersion});

  final int dbVersion;
  final int codeVersion;

  @override
  String toString() =>
      'DowngradeDetected: DB 스키마 v$dbVersion > 앱 지원 v$codeVersion';
}

/// drift가 DB를 열기 전에 실행하는 안전장치.
///
/// - 다운그레이드 감지 시 [DowngradeDetected]를 던져 열기를 막는다.
/// - 마이그레이션이 임박했으면(user_version < 코드 버전) DB 파일을 먼저
///   복사해 둔다. 마이그레이션이 어떤 이유로 깨져도 원본 파일이 남는다.
/// - WAL 모드에서는 최근 쓰기가 -wal 파일에 남아 있을 수 있으므로
///   -wal/-shm 파일을 반드시 동반 복사한다.
Future<void> runPreOpenGuard(File dbFile, int codeSchemaVersion) async {
  if (!dbFile.existsSync()) return;

  final int dbVersion;
  final raw = sq.sqlite3.open(dbFile.path, mode: sq.OpenMode.readOnly);
  try {
    dbVersion = raw.select('PRAGMA user_version').first.values.first as int;
  } finally {
    raw.close();
  }

  if (dbVersion > codeSchemaVersion) {
    throw DowngradeDetected(
      dbVersion: dbVersion,
      codeVersion: codeSchemaVersion,
    );
  }
  if (dbVersion > 0 && dbVersion < codeSchemaVersion) {
    _backupBeforeMigration(dbFile, codeSchemaVersion);
  }
}

void _backupBeforeMigration(File dbFile, int targetVersion) {
  // 마이그레이션이 중간에 죽고 재시도되는 경우, 이미 만들어 둔 순정 백업을
  // 반쯤 적용된 DB로 덮어쓰면 안 된다 — 같은 target 백업이 있으면 건너뛴다.
  if (File('${dbFile.path}.pre_v$targetVersion.bak').existsSync()) return;
  for (final suffix in const ['', '-wal', '-shm']) {
    final src = File(dbFile.path + suffix);
    if (src.existsSync()) {
      src.copySync('${dbFile.path}.pre_v$targetVersion$suffix.bak');
    }
  }
  _rotateBackups(dbFile, keep: 2);
}

final RegExp _backupPattern = RegExp(r'\.pre_v(\d+)(-wal|-shm)?\.bak$');

/// pre_v{N} 백업 세트를 최신 [keep]개 버전만 남기고 정리한다.
void _rotateBackups(File dbFile, {required int keep}) {
  final dir = dbFile.parent;
  final prefix = dbFile.path;
  final versions = <int>{};
  final files = <int, List<File>>{};
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.startsWith(prefix)) continue;
    final m = _backupPattern.firstMatch(f.path);
    if (m == null) continue;
    final v = int.parse(m.group(1)!);
    versions.add(v);
    (files[v] ??= []).add(f);
  }
  final sorted = versions.toList()..sort();
  while (sorted.length > keep) {
    final oldest = sorted.removeAt(0);
    for (final f in files[oldest]!) {
      f.deleteSync();
    }
  }
}
