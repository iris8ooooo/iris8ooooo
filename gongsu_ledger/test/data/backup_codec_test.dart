import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/memo_repository.dart';
import 'package:gongsu_ledger/data/repositories/preset_repository.dart';
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
    final deletedId = await repo.addCustom(dateKey: 20260803, centiGongsu: 50);
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
    expect(
      (await target.select(target.workEntries).get()).length,
      (await source.select(source.workEntries).get()).length,
    );
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

    expect(
      () => importBackupJson(target, 'not json'),
      throwsA(isA<BackupFormatError>()),
    );
    expect(
      () => importBackupJson(target, '{"format":"other"}'),
      throwsA(isA<BackupFormatError>()),
    );

    final entries = await target.select(target.workEntries).get();
    expect(entries.length, 1);
  });

  test('더 새로운 스키마의 백업은 조용히 깎지 않고 거부한다', () async {
    await seedSource();
    final envelope =
        jsonDecode(await exportBackupJson(source)) as Map<String, Object?>;
    envelope['schemaVersion'] = AppDatabase.codeSchemaVersion + 1;

    expect(
      () => importBackupJson(source, jsonEncode(envelope)),
      throwsA(isA<BackupTooNew>()),
    );
  });

  test('삭제가 병합으로 전파된다 (softDelete가 updatedAt을 올리므로)', () async {
    final repo = WorkEntryRepository(source.workEntryDao);
    final id = await repo.addCustom(dateKey: 20260805, centiGongsu: 100);

    // 삭제 전 백업을 다른 기기에 병합
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await importBackupJson(target, await exportBackupJson(source));
    expect((await target.workEntryDao.getRange(20260805, 20260805)).length, 1);

    // 원 기기에서 삭제 → 새 백업 → 다시 병합 → 삭제가 전파된다
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.softDelete(id);
    await importBackupJson(target, await exportBackupJson(source));
    expect(await target.workEntryDao.getRange(20260805, 20260805), isEmpty);
  });

  test('사용자가 수정한 시드 프리셋이 새 기기의 시드를 이긴다 (시드 ts=0)', () async {
    final presets = await source.presetDao.getActive();
    final seed = presets.firstWhere((p) => p.name == '1.5공수');
    await PresetRepository(source.presetDao)
        .update(id: seed.id, name: '1.8공수', centiGongsu: 180, colorId: 3);
    final json = await exportBackupJson(source);

    // 새 기기: 방금 시드된 상태(수정 안 함)에 병합
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await importBackupJson(target, json);

    final merged = (await target.presetDao.getActive()).firstWhere(
      (p) => p.uid == seed.uid,
    );
    expect(merged.name, '1.8공수');
    expect(merged.centiGongsu, 180); // 수정값이 유실되지 않는다
  });

  test('기록↔프리셋 연결이 uid로 재매핑된다 (로컬 id 어긋남 극복)', () async {
    final preset = (await source.presetDao.getActive()).first;
    await WorkEntryRepository(source.workEntryDao)
        .addFromPreset(dateKey: 20260805, preset: preset);
    final json = await exportBackupJson(source);

    // 대상 기기는 자기 프리셋을 먼저 만들어 autoincrement id가 어긋난 상태
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await PresetRepository(target.presetDao)
        .create(name: '내프리셋', centiGongsu: 120, colorId: 5);
    await importBackupJson(target, json);

    final entry = (await target.workEntryDao.getRange(
      20260805,
      20260805,
    )).single;
    final linked = (await target.select(target.presets).get()).firstWhere(
      (p) => p.id == entry.presetId,
    );
    expect(linked.uid, preset.uid); // id가 아니라 정체(uid)가 보존된다
  });

  test('지운 메모가 옛 백업 병합으로 부활하지 않는다 (tombstone)', () async {
    final memoRepo = MemoRepository(source.memoDao);
    await memoRepo.setMemo(dateKey: 20260810, body: '민감한 메모');
    final oldBackup = await exportBackupJson(source);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await memoRepo.setMemo(dateKey: 20260810, body: ''); // 삭제(tombstone)
    expect(await source.memoDao.watchMemo(20260810).first, null);

    await importBackupJson(source, oldBackup);
    expect(await source.memoDao.watchMemo(20260810).first, null); // 부활 없음
  });

  test('메모 삭제도 기기 간 전파된다', () async {
    final memoRepo = MemoRepository(source.memoDao);
    await memoRepo.setMemo(dateKey: 20260810, body: '메모');

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await importBackupJson(target, await exportBackupJson(source));
    expect((await target.memoDao.watchMemo(20260810).first)?.body, '메모');

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await memoRepo.setMemo(dateKey: 20260810, body: '');
    await importBackupJson(target, await exportBackupJson(source));
    expect(await target.memoDao.watchMemo(20260810).first, null);
  });

  test('프리셋 순서 변경이 병합으로 전파된다 (reorder가 updatedAt을 올리므로)', () async {
    final presets = await source.presetDao.getActive();
    final reversed = presets.map((p) => p.id).toList().reversed.toList();
    await PresetRepository(source.presetDao).reorder(reversed);
    final json = await exportBackupJson(source);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await importBackupJson(target, json);

    final sourceOrder = (await source.presetDao.getActive())
        .map((p) => p.uid)
        .toList();
    final targetOrder = (await target.presetDao.getActive())
        .map((p) => p.uid)
        .toList();
    expect(targetOrder, sourceOrder);
  });

  test('오염된 행(음수 공수·엉뚱한 날짜)은 건너뛰고 skipped로 보고한다', () async {
    await seedSource();
    final envelope =
        jsonDecode(await exportBackupJson(source)) as Map<String, Object?>;
    final entries = (envelope['workEntries'] as List)
        .cast<Map<String, Object?>>();
    entries.add({
      'uid': '11111111-1111-4111-8111-111111111111',
      'dateKey': 20260815,
      'centiGongsu': -100, // 음수 공수 — 월 합계 오염 시도
      'updatedAtMillis': 1,
      'createdAtMillis': 1,
    });
    entries.add({
      'uid': '22222222-2222-4222-8222-222222222222',
      // dateKey 누락 — 유령 데이터 시도
      'centiGongsu': 100,
      'updatedAtMillis': 1,
      'createdAtMillis': 1,
    });
    entries.add({
      'uid': '33333333-3333-4333-8333-333333333333',
      'dateKey': 99999999, // 존재할 수 없는 날짜
      'centiGongsu': 100,
      'updatedAtMillis': 1,
      'createdAtMillis': 1,
    });

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final result = await importBackupJson(target, jsonEncode(envelope));

    expect(result.skipped, 3);
    final all = await target.select(target.workEntries).get();
    expect(all.any((e) => e.centiGongsu < 0), false);
    expect(all.any((e) => e.dateKey == 0), false);
    expect(all.any((e) => e.dateKey == 99999999), false);
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
