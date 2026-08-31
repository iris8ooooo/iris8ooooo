import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/pre_open_guard.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('guard_test');
    dbFile = File('${tempDir.path}/gongsu.db');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void createDb(int userVersion, {bool wal = false}) {
    final db = sq.sqlite3.open(dbFile.path);
    if (wal) db.execute('PRAGMA journal_mode = WAL');
    db.execute('CREATE TABLE IF NOT EXISTS t (a INTEGER)');
    db.execute('INSERT INTO t VALUES (1)');
    db.execute('PRAGMA user_version = $userVersion');
    db.close();
  }

  test('DB 파일이 없으면 아무 일도 없다', () async {
    await runPreOpenGuard(dbFile, 1);
    expect(tempDir.listSync(), isEmpty);
  });

  test('같은 버전이면 백업하지 않는다', () async {
    createDb(1);
    await runPreOpenGuard(dbFile, 1);
    expect(
        tempDir.listSync().where((f) => f.path.endsWith('.bak')), isEmpty);
  });

  test('업그레이드 직전에는 파일 백업을 만든다', () async {
    createDb(1);
    await runPreOpenGuard(dbFile, 2);
    expect(File('${dbFile.path}.pre_v2.bak').existsSync(), true);
  });

  test('WAL 파일이 있으면 함께 백업한다 (최근 쓰기 유실 방지)', () async {
    createDb(1, wal: true);
    // WAL 모드에서 쓰기 후 checkpoint 없이 닫지 않은 상태를 흉내내기 위해
    // -wal 파일을 직접 만들어 둔다 (실기기에서는 크래시 등으로 남는다).
    File('${dbFile.path}-wal').writeAsBytesSync([1, 2, 3]);
    await runPreOpenGuard(dbFile, 2);
    expect(File('${dbFile.path}.pre_v2.bak').existsSync(), true);
    expect(File('${dbFile.path}.pre_v2-wal.bak').existsSync(), true);
  });

  test('백업 세트는 최신 2개 버전만 남긴다', () async {
    createDb(1);
    await runPreOpenGuard(dbFile, 2);
    createDb(2);
    await runPreOpenGuard(dbFile, 3);
    createDb(3);
    await runPreOpenGuard(dbFile, 4);

    expect(File('${dbFile.path}.pre_v2.bak').existsSync(), false); // 정리됨
    expect(File('${dbFile.path}.pre_v3.bak').existsSync(), true);
    expect(File('${dbFile.path}.pre_v4.bak').existsSync(), true);
  });

  test('다운그레이드는 열지 않고 예외 (파괴적 재생성 금지)', () async {
    createDb(5);
    expect(() => runPreOpenGuard(dbFile, 1),
        throwsA(isA<DowngradeDetected>()));
    // 파일은 그대로 남는다
    final db = sq.sqlite3.open(dbFile.path, mode: sq.OpenMode.readOnly);
    expect(db.select('SELECT COUNT(*) c FROM t').first.values.first, 1);
    db.close();
  });
}
