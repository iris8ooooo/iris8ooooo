import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/db_rescue.dart';

void main() {
  test('열리지 않는 DB 파일은 지우지 않고 .corrupt_<시각>.bak 으로 옮긴다', () async {
    final dir = Directory.systemTemp.createTempSync('rescue');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/gongsu.db').writeAsStringSync('db');
    File('${dir.path}/gongsu.db-wal').writeAsStringSync('wal');
    File('${dir.path}/other.txt').writeAsStringSync('x');

    final moved = await quarantineDatabaseFiles(dir, nowMillis: 123);
    expect(moved.length, 2);
    expect(File('${dir.path}/gongsu.db').existsSync(), false);
    expect(
      File('${dir.path}/gongsu.db.corrupt_123.bak').readAsStringSync(),
      'db',
    );
    expect(
      File('${dir.path}/gongsu.db.corrupt_123-wal.bak').readAsStringSync(),
      'wal',
    );
    expect(File('${dir.path}/other.txt').existsSync(), true);
    // 파일이 없으면 아무 일도 없다.
    expect(await quarantineDatabaseFiles(dir, nowMillis: 124), isEmpty);
  });
}
