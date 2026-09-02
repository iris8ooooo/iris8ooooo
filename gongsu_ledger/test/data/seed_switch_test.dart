import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/preset_repository.dart';
import 'package:gongsu_ledger/data/seed/default_presets.dart';
import 'package:gongsu_ledger/data/seed/seed_switch.dart';

void main() {
  ExistingPreset row({
    required int id,
    required String uid,
    bool isArchived = false,
    int createdAt = 0,
    int updatedAt = 0,
  }) => (
    id: id,
    uid: uid,
    isArchived: isArchived,
    createdAtMillis: createdAt,
    updatedAtMillis: updatedAt,
  );

  group('planSeedSwitch (순수)', () {
    final construction = constructionSeedPresets;
    final shipyard = shipyardSeedPresets;

    test('건설 시드만 있는 새 기기 → 조선소: 건설 5개 보관, 조선소 6개 삽입', () {
      final existing = [
        for (var i = 0; i < construction.length; i++)
          row(id: i + 1, uid: construction[i].uid),
      ];
      final plan = planSeedSwitch(existing: existing, target: shipyard);
      expect(plan.archiveIds, [1, 2, 3, 4, 5]);
      expect(plan.unarchiveIds, isEmpty);
      expect(plan.inserts.map((s) => s.uid), shipyard.map((s) => s.uid));
    });

    test('사용자가 손댄 시드(updatedAt ≠ createdAt)와 직접 만든 프리셋은 불변', () {
      final existing = [
        row(id: 1, uid: construction[0].uid, updatedAt: 5), // 이름을 고친 시드
        row(id: 2, uid: construction[1].uid),
        row(id: 3, uid: 'user-made-uid-000000000000000000000000', updatedAt: 9),
      ];
      final plan = planSeedSwitch(existing: existing, target: shipyard);
      expect(plan.archiveIds, [2]);
      expect(plan.inserts.length, shipyard.length);
    });

    test('다시 건설로 돌아오면 보관된 건설 시드를 되살리고 조선소 시드를 보관', () {
      final existing = [
        for (var i = 0; i < construction.length; i++)
          row(id: i + 1, uid: construction[i].uid, isArchived: true),
        for (var i = 0; i < shipyard.length; i++)
          row(id: 10 + i, uid: shipyard[i].uid),
      ];
      final plan = planSeedSwitch(existing: existing, target: construction);
      expect(plan.unarchiveIds, [1, 2, 3, 4, 5]);
      expect(plan.archiveIds, [10, 11, 12, 13, 14, 15]);
      expect(plan.inserts, isEmpty);
    });

    test('같은 직군을 다시 고르면 아무 일도 없다', () {
      final existing = [
        for (var i = 0; i < construction.length; i++)
          row(id: i + 1, uid: construction[i].uid),
      ];
      expect(
        planSeedSwitch(existing: existing, target: construction).isNoop,
        true,
      );
    });

    test('직접 만들기: 미수정 시드는 모두 보관, 삽입 없음', () {
      final existing = [
        for (var i = 0; i < construction.length; i++)
          row(id: i + 1, uid: construction[i].uid),
        row(id: 9, uid: construction[2].uid, updatedAt: 3), // 손댄 것
      ];
      final plan = planSeedSwitch(existing: existing, target: const []);
      expect(plan.archiveIds, [1, 2, 3, 4, 5]);
      expect(plan.inserts, isEmpty);
    });
  });

  group('PresetRepository.applyJobSeed (DB)', () {
    late AppDatabase db;
    late PresetRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PresetRepository(db.presetDao);
    });

    tearDown(() => db.close());

    test('조선소 선택 → 활성 프리셋이 조선소 세트, 건설 세트는 보관(삭제 아님)', () async {
      await repo.applyJobSeed(JobKind.shipyard);
      final active = await db.presetDao.getActive();
      expect(active.map((p) => p.name), [
        'A(0.9)',
        'B(1.0)',
        'E잔업',
        '야간',
        '반공',
        '휴무',
      ]);
      final all = await db.presetDao.getAll();
      expect(all.length, 11, reason: '물리 삭제 없음');
      expect(
        all.where((p) => p.isArchived).map((p) => p.updatedAtMillis).toSet(),
        {0},
        reason: '조용한 보관 — updatedAt 불변',
      );
    });

    test('이름을 고친 건설 시드는 조선소로 바꿔도 남는다', () async {
      final active = await db.presetDao.getActive();
      final touched = active.first;
      await repo.update(
        id: touched.id,
        name: '본공수',
        centiGongsu: touched.centiGongsu,
        colorId: touched.colorId,
      );
      await repo.applyJobSeed(JobKind.shipyard);
      final names = (await db.presetDao.getActive()).map((p) => p.name);
      expect(names, contains('본공수'));
      expect(names, contains('A(0.9)'));
      expect(names, isNot(contains('1.5공수')));
    });

    test('건설 → 조선소 → 건설: 되살아나고 중복 생성 없음', () async {
      await repo.applyJobSeed(JobKind.shipyard);
      await repo.applyJobSeed(JobKind.construction);
      final active = await db.presetDao.getActive();
      expect(active.map((p) => p.name), ['1공수', '1.5공수', '2공수', '반공수', '휴무']);
      expect((await db.presetDao.getAll()).length, 11);
    });
  });
}
