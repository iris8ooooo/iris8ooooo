import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/memo_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';

void main() {
  late AppDatabase source;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => source.close());

  Future<void> seedSource() async {
    final repo = WorkEntryRepository(source.workEntryDao);
    await repo.addCustom(dateKey: 20260801, centiGongsu: 180);
    await repo.addCustom(dateKey: 20260802, centiGongsu: 100);
    final deletedId =
        await repo.addCustom(dateKey: 20260803, centiGongsu: 50);
    await repo.softDelete(deletedId);
    await MemoRepository(source.memoDao)
        .setMemo(dateKey: 20260801, body: '거푸집 해체');
  }

  test('내보내기 → 새 기기 가져오기 라운드트립 (삭제 행 포함)', () async {
    await seedSource();
    final json = await exportBackupJson(source);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final result = await importBackupJson(target, json);

    final srcEntries = await source.select(source.workEntries).get();
    final dstEntries = await target.select(target.workEntries).get();
    expect(dstEntries.length, srcEntries.length);
    for (final s in srcEntries) {
      final d = dstEntries.singleWhere((e) => e.uid == s.uid);
      expect(d.dateKey, s.dateKey);
      expect(d.centiGongsu, s.centiGongsu);
      expect(d.deletedAtMillis, s.deletedAtMillis); // 삭제 상태 보존
    }
    // 시드 프리셋은 고정 uid라 중복 생성이 없다.
    final dstPresets = await target.select(target.presets).get();
    final srcPresets = await source.select(source.presets).get();
    expect(dstPresets.length, srcPresets.length);

    final memo = await target.memoDao.watchMemo(20260801).first;
    expect(memo?.body, '거푸집 해체');
    expect(result.inserted, greaterThan(0));
  });

  test('같은 백업을 두 번 가져와도 중복이 없다 (멱등)', () async {
    await seedSource();
    final json = await exportBackupJson(source);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await importBackupJson(target, json);
    final second = await importBackupJson(target, json);

    expect(second.inserted, 0);
    expect(second.updated, 0);
    expect((await target.select(target.workEntries).get()).length,
        (await source.select(source.workEntries).get()).length);
  });

  test('병합은 updatedAt 최신 승리, 기존 행을 지우지 않는다', () async {
    await seedSource();
    final json = await exportBackupJson(source);

    // 대상 기기에 자체 기록이 있는 상태에서 병합
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final targetRepo = WorkEntryRepository(target.workEntryDao);
    await targetRepo.addCustom(dateKey: 20260810, centiGongsu: 200);

    await importBackupJson(target, json);
    final entries = await target.select(target.workEntries).get();
    expect(entries.any((e) => e.dateKey == 20260810), true); // 기존 유지
    expect(entries.any((e) => e.dateKey == 20260801), true); // 병합됨
  });

  test('형식이 아니면 거부, 데이터 불변', () async {
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await WorkEntryRepository(target.workEntryDao)
        .addCustom(dateKey: 20260810, centiGongsu: 100);

    expect(() => importBackupJson(target, 'not json'),
        throwsA(isA<BackupFormatError>()));
    expect(() => importBackupJson(target, '{"format":"other"}'),
        throwsA(isA<BackupFormatError>()));

    final entries = await target.select(target.workEntries).get();
    expect(entries.length, 1);
  });

  test('더 새로운 스키마의 백업은 조용히 깎지 않고 거부한다', () async {
    await seedSource();
    final envelope =
        jsonDecode(await exportBackupJson(source)) as Map<String, Object?>;
    envelope['schemaVersion'] = AppDatabase.codeSchemaVersion + 1;

    expect(() => importBackupJson(source, jsonEncode(envelope)),
        throwsA(isA<BackupTooNew>()));
  });

  test('forward-tolerant: 모르는 키는 무시하고 가져온다', () async {
    await seedSource();
    final envelope =
        jsonDecode(await exportBackupJson(source)) as Map<String, Object?>;
    envelope['unknownTable'] = [1, 2, 3];
    final entries = envelope['workEntries'] as List;
    (entries.first as Map<String, Object?>)['unknownColumn'] = 'x';

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final result = await importBackupJson(target, jsonEncode(envelope));
    expect(result.inserted, greaterThan(0));
  });
}
