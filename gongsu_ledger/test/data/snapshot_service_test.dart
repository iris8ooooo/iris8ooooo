import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/snapshot_service.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late SnapshotService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('snapshot_test');
    db = AppDatabase(NativeDatabase.memory());
    service = SnapshotService(rootDirectory: () async => tempDir, keepDays: 7);
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test('스냅샷 생성 → 목록 → 복원 (병합)', () async {
    final repo = WorkEntryRepository(db.workEntryDao);
    await repo.addCustom(dateKey: 20260901, centiGongsu: 180);
    await service.writeSnapshot(db, 20260902);

    final list = await service.list();
    expect(list.length, 1);
    expect(list.single.dateKey, 20260902);
    expect(list.single.sizeBytes, greaterThan(0));
    expect(list.single.file.path.endsWith('snapshot_20260902.gsjb'), true);

    // 새 기기(빈 DB)에 복원
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    final result = await service.restore(fresh, list.single);
    expect(result.inserted, greaterThan(0));
    final rows = await fresh.workEntryDao.getRange(20260901, 20260901);
    expect(rows.single.centiGongsu, 180);
  });

  test('하루 한 번만 만들고, 같은 날은 건너뛴다', () async {
    expect(await service.ensureDailySnapshot(db, 20260902), true);
    expect(await service.ensureDailySnapshot(db, 20260902), false);
    expect((await service.list()).length, 1);
  });

  test('최근 7일치만 남긴다', () async {
    for (var d = 1; d <= 10; d++) {
      await service.writeSnapshot(db, 20260900 + d);
    }
    final list = await service.list();
    expect(list.length, 7);
    expect(list.first.dateKey, 20260910); // 최신 먼저
    expect(list.last.dateKey, 20260904);
    expect(
      File('${tempDir.path}/snapshots/snapshot_20260901.gsjb').existsSync(),
      false,
    );
  });

  test('스냅샷 폴더의 다른 파일과 임시 파일은 무시한다', () async {
    await service.writeSnapshot(db, 20260902);
    final dir = Directory('${tempDir.path}/snapshots');
    File('${dir.path}/notes.txt').writeAsStringSync('x');
    File('${dir.path}/snapshot_20260903.gsjb.tmp').writeAsStringSync('half');
    final list = await service.list();
    expect(list.length, 1);
  });

  test('오래된 스냅샷을 병합해도 그 뒤에 지운 기록이 부활하지 않는다', () async {
    final repo = WorkEntryRepository(db.workEntryDao);
    final id = await repo.addCustom(dateKey: 20260901, centiGongsu: 100);
    await service.writeSnapshot(db, 20260901);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.softDelete(id);

    final snap = (await service.list()).single;
    await service.restore(db, snap);
    expect(await db.workEntryDao.getRange(20260901, 20260901), isEmpty);
  });
}
