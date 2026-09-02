import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;

/// 릴리스 게이트: 모든 (구버전 → 최신) 마이그레이션이
/// ① 스키마가 코드와 일치하고 ② 구버전 데이터가 값 그대로 읽히는지 검증한다.
/// "스키마만 맞고 데이터가 증발"하는 사고를 잡는 것은 ②다.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 → v2 마이그레이션 후 스키마가 코드 정의와 일치한다', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v2 → v2 (최신 버전 그대로 열기) 도 일치한다', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test('v1 골든 데이터 100건이 v2 마이그레이션 후 전부 동일 값으로 읽힌다', () async {
    final entries = [
      for (var i = 0; i < 100; i++)
        v1.WorkEntriesData(
          id: i + 1,
          uid: '00000000-0000-4000-8000-${(i + 1).toString().padLeft(12, '0')}',
          dateKey: 20260801 + (i % 28),
          centiGongsu: [100, 150, 180, 50, 0, 235][i % 6],
          presetId: i % 3 == 0 ? 1 : null,
          labelSnapshot: i % 3 == 0 ? '1공수' : '',
          colorIdSnapshot: i % 12,
          siteId: null,
          unitRateWonOverride: null,
          createdAtMillis: 1000 + i,
          updatedAtMillis: 2000 + i,
          deletedAtMillis: i % 10 == 9 ? 3000 + i : null, // soft delete 행 포함
        ),
    ];
    final presets = [
      v1.PresetsData(
        id: 1,
        uid: '00000000-0000-4000-8000-0000000c0001',
        name: '1공수',
        centiGongsu: 100,
        colorId: 0,
        sortOrder: 0,
        isArchived: 0,
        createdAtMillis: 0,
        updatedAtMillis: 0,
      ),
      v1.PresetsData(
        id: 2,
        uid: '00000000-0000-4000-8000-0000000c0002',
        name: '수정한프리셋',
        centiGongsu: 180,
        colorId: 3,
        sortOrder: 1,
        isArchived: 1,
        createdAtMillis: 0,
        updatedAtMillis: 5000,
      ),
    ];
    final memos = [
      v1.DayMemosData(dateKey: 20260805, body: '거푸집 해체', updatedAtMillis: 10),
      v1.DayMemosData(dateKey: 20260806, body: '', updatedAtMillis: 11),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.workEntries, entries);
        batch.insertAll(oldDb.presets, presets);
        batch.insertAll(oldDb.dayMemos, memos);
      },
      validateItems: (newDb) async {
        final rows = await newDb.select(newDb.workEntries).get();
        expect(rows.length, entries.length);
        for (final e in entries) {
          final r = rows.singleWhere((x) => x.uid == e.uid);
          expect(r.dateKey, e.dateKey);
          expect(r.centiGongsu, e.centiGongsu);
          expect(r.presetId, e.presetId);
          expect(r.labelSnapshot, e.labelSnapshot);
          expect(r.colorIdSnapshot, e.colorIdSnapshot);
          expect(r.updatedAtMillis, e.updatedAtMillis);
          expect(r.deletedAtMillis, e.deletedAtMillis);
          expect(r.siteId, null);
        }

        final presetRows = await newDb.select(newDb.presets).get();
        expect(presetRows.length, 2);
        expect(presetRows.singleWhere((p) => p.id == 2).isArchived, 1);
        expect(presetRows.singleWhere((p) => p.id == 2).updatedAtMillis, 5000);

        final memoRows = await newDb.select(newDb.dayMemos).get();
        expect(memoRows.length, 2);
        expect(
          memoRows.singleWhere((m) => m.dateKey == 20260805).body,
          '거푸집 해체',
        );

        // 새 테이블은 존재하고 비어 있다 (시드 재실행 없음)
        expect(await newDb.select(newDb.sites).get(), isEmpty);
        expect(await newDb.select(newDb.siteRateHistories).get(), isEmpty);
        expect(await newDb.select(newDb.dayExtraItems).get(), isEmpty);
      },
    );
  });
}
