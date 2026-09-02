import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
import 'generated_migrations/schema_v3.dart' as v3;

/// 릴리스 게이트: 모든 (구버전 → 최신) 마이그레이션이
/// ① 스키마가 코드와 일치하고 ② 구버전 데이터가 값 그대로 읽히는지 검증한다.
/// "스키마만 맞고 데이터가 증발"하는 사고를 잡는 것은 ②다.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  const latest = AppDatabase.codeSchemaVersion;

  for (final from in [1, 2, 3]) {
    test('v$from → v$latest 마이그레이션 후 스키마가 코드 정의와 일치한다', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, latest);
    });
  }

  test('v1 골든 데이터 100건이 v$latest 마이그레이션 후 전부 동일 값으로 읽힌다', () async {
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
      newVersion: latest,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
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

  test('v2 골든 데이터(업체·이력·항목)가 v$latest 후 보존되고 taxMode 기본값이 채워진다', () async {
    final sites = [
      v2.SitesData(
        id: 1,
        uid: '00000000-0000-4000-8000-0000000a0001',
        name: 'A현장',
        colorId: 2,
        sortOrder: 0,
        isArchived: 0,
        createdAtMillis: 100,
        updatedAtMillis: 200,
      ),
      v2.SitesData(
        id: 2,
        uid: '00000000-0000-4000-8000-0000000a0002',
        name: '보관된현장',
        colorId: 5,
        sortOrder: 1,
        isArchived: 1,
        createdAtMillis: 100,
        updatedAtMillis: 300,
      ),
    ];
    final rates = [
      v2.SiteRateHistoriesData(
        id: 1,
        uid: '00000000-0000-4000-8000-0000000b0001',
        siteId: 1,
        effectiveFromDateKey: 20000101,
        dailyRateWon: 150000,
        createdAtMillis: 1,
        updatedAtMillis: 1,
        deletedAtMillis: null,
      ),
      v2.SiteRateHistoriesData(
        id: 2,
        uid: '00000000-0000-4000-8000-0000000b0002',
        siteId: 1,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 165000,
        createdAtMillis: 2,
        updatedAtMillis: 2,
        deletedAtMillis: 99, // soft delete 이력
      ),
    ];
    final items = [
      v2.DayExtraItemsData(
        id: 1,
        uid: '00000000-0000-4000-8000-0000000e0001',
        dateKey: 20260805,
        siteId: 1,
        kind: 'allowance',
        label: '식비',
        amountWon: 10000,
        isTaxable: 1,
        createdAtMillis: 1,
        updatedAtMillis: 1,
        deletedAtMillis: null,
      ),
      v2.DayExtraItemsData(
        id: 2,
        uid: '00000000-0000-4000-8000-0000000e0002',
        dateKey: 20260806,
        siteId: null,
        kind: 'deduction',
        label: '가불',
        amountWon: 50000,
        isTaxable: 0,
        createdAtMillis: 1,
        updatedAtMillis: 1,
        deletedAtMillis: null,
      ),
    ];
    final entries = [
      v2.WorkEntriesData(
        id: 1,
        uid: '00000000-0000-4000-8000-0000000f0001',
        dateKey: 20260805,
        centiGongsu: 150,
        presetId: null,
        labelSnapshot: '',
        colorIdSnapshot: 0,
        siteId: 1,
        unitRateWonOverride: 200000,
        createdAtMillis: 1,
        updatedAtMillis: 1,
        deletedAtMillis: null,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: latest,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.sites, sites);
        batch.insertAll(oldDb.siteRateHistories, rates);
        batch.insertAll(oldDb.dayExtraItems, items);
        batch.insertAll(oldDb.workEntries, entries);
      },
      validateItems: (newDb) async {
        final siteRows = await newDb.select(newDb.sites).get();
        expect(siteRows.length, 2);
        for (final s in siteRows) {
          expect(s.taxMode, 'none'); // ADD COLUMN 기본값
          expect(s.taxOptionsJson, null);
        }
        expect(siteRows.singleWhere((s) => s.id == 2).isArchived, 1);
        expect(siteRows.singleWhere((s) => s.id == 1).colorId, 2);

        final rateRows = await newDb.select(newDb.siteRateHistories).get();
        expect(rateRows.length, 2);
        expect(rateRows.singleWhere((r) => r.id == 2).deletedAtMillis, 99);
        expect(rateRows.singleWhere((r) => r.id == 1).dailyRateWon, 150000);

        final itemRows = await newDb.select(newDb.dayExtraItems).get();
        expect(itemRows.length, 2);
        expect(itemRows.singleWhere((i) => i.id == 1).isTaxable, 1);
        expect(itemRows.singleWhere((i) => i.id == 2).siteId, null);
        expect(itemRows.singleWhere((i) => i.id == 2).amountWon, 50000);

        final entry = (await newDb.select(newDb.workEntries).get()).single;
        expect(entry.siteId, 1);
        expect(entry.unitRateWonOverride, 200000);
        expect(entry.centiGongsu, 150);
      },
    );
  });
}
