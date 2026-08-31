import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/data/seed/default_presets.dart';

void main() {
  late AppDatabase db;
  late WorkEntryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkEntryRepository(db.workEntryDao);
  });

  tearDown(() => db.close());

  test('최초 생성 시 건설형 프리셋이 시드된다 (고정 uid)', () async {
    final presets = await db.presetDao.getActive();
    expect(presets.length, constructionSeedPresets.length);
    expect(presets.map((p) => p.uid).toSet(),
        constructionSeedPresets.map((s) => s.uid).toSet());
    expect(presets.first.name, '1공수');
    expect(presets.first.centiGongsu, 100);
  });

  test('프리셋 입력은 이름/색을 스냅샷으로 복사한다', () async {
    final preset = (await db.presetDao.getActive()).first;
    await repo.addFromPreset(dateKey: 20260801, preset: preset);

    final entries = await db.workEntryDao.getRange(20260801, 20260801);
    expect(entries.length, 1);
    expect(entries.first.centiGongsu, preset.centiGongsu);
    expect(entries.first.labelSnapshot, preset.name);
    expect(entries.first.colorIdSnapshot, preset.colorId);
    expect(entries.first.presetId, preset.id);
    expect(entries.first.uid.length, 36);
  });

  test('프리셋을 수정/보관해도 과거 기록 표시는 불변', () async {
    final preset = (await db.presetDao.getActive()).first;
    await repo.addFromPreset(dateKey: 20260801, preset: preset);

    final presetRepo = PresetRepositoryForTest(db);
    await presetRepo.renameAndArchive(preset.id);

    final entries = await db.workEntryDao.getRange(20260801, 20260801);
    expect(entries.first.labelSnapshot, preset.name); // 원래 이름 유지
    expect(entries.first.centiGongsu, preset.centiGongsu);
  });

  test('watchMonth는 월 경계를 정확히 지킨다 (1일/말일 포함, 이웃 달 제외)', () async {
    await repo.addCustom(dateKey: 20260801, centiGongsu: 100);
    await repo.addCustom(dateKey: 20260831, centiGongsu: 150);
    await repo.addCustom(dateKey: 20260731, centiGongsu: 100); // 전월 말일
    await repo.addCustom(dateKey: 20260901, centiGongsu: 100); // 익월 1일

    final rows = await db.workEntryDao.watchMonth(202608).first;
    expect(rows.map((e) => e.dateKey).toList(), [20260801, 20260831]);
  });

  test('하루 여러 건 — 입력 순서(id) 유지', () async {
    await repo.addCustom(dateKey: 20260805, centiGongsu: 100);
    await repo.addCustom(dateKey: 20260805, centiGongsu: 150);
    await repo.addCustom(dateKey: 20260805, centiGongsu: 50);

    final rows = await db.workEntryDao.watchMonth(202608).first;
    expect(rows.map((e) => e.centiGongsu).toList(), [100, 150, 50]);
  });

  test('soft delete는 조회에서 빠지고, 복원하면 돌아온다', () async {
    final id = await repo.addCustom(dateKey: 20260805, centiGongsu: 180);
    await repo.softDelete(id);

    expect(await db.workEntryDao.watchMonth(202608).first, isEmpty);
    expect(await db.workEntryDao.getById(id), null);

    await repo.restore(id);
    final rows = await db.workEntryDao.watchMonth(202608).first;
    expect(rows.single.centiGongsu, 180);
  });

  test('soft delete/복원은 updatedAtMillis도 갱신한다 (백업 병합 LWW 전제)', () async {
    final id = await repo.addCustom(dateKey: 20260805, centiGongsu: 100);
    final created = (await db.select(db.workEntries).get()).single;

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.softDelete(id);
    final deleted = (await db.select(db.workEntries).get()).single;
    expect(deleted.updatedAtMillis, greaterThan(created.updatedAtMillis));

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.restore(id);
    final restored = (await db.select(db.workEntries).get()).single;
    expect(restored.updatedAtMillis, greaterThan(deleted.updatedAtMillis));
  });

  test('soft delete된 행은 DB에는 남는다 (물리 삭제 없음)', () async {
    final id = await repo.addCustom(dateKey: 20260805, centiGongsu: 180);
    await repo.softDelete(id);

    final all = await db.select(db.workEntries).get();
    expect(all.length, 1);
    expect(all.single.deletedAtMillis, isNotNull);
    expect(all.single.centiGongsu, 180); // 값도 그대로
  });

  test('값 수정 시 직접 입력으로 전환 (라벨 해제, 색 유지)', () async {
    final preset = (await db.presetDao.getActive()).first;
    final id =
        await repo.addFromPreset(dateKey: 20260805, preset: preset);
    await repo.updateValue(id: id, centiGongsu: 180);

    final entry = (await db.workEntryDao.getById(id))!;
    expect(entry.centiGongsu, 180);
    expect(entry.presetId, null);
    expect(entry.labelSnapshot, '');
    expect(entry.colorIdSnapshot, preset.colorId); // 색은 유지
  });

  test('음수 공수는 거부된다', () async {
    expect(() => repo.addCustom(dateKey: 20260805, centiGongsu: -5),
        throwsArgumentError);
  });
}

/// 프리셋 수정+보관을 한 번에 하는 테스트 헬퍼.
class PresetRepositoryForTest {
  PresetRepositoryForTest(this.db);
  final AppDatabase db;

  Future<void> renameAndArchive(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.presetDao.updateFields(
        id,
        PresetsCompanion(
            name: const Value('바뀐이름'), updatedAtMillis: Value(now)));
    await db.presetDao.archive(id, now);
  }
}
