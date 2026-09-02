import 'package:drift/drift.dart';

import '../seed/default_presets.dart';
import 'daos/day_item_dao.dart';
import 'daos/memo_dao.dart';
import 'daos/preset_dao.dart';
import 'daos/site_dao.dart';
import 'daos/work_entry_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WorkEntries,
    Presets,
    DayMemos,
    AppSettings,
    Sites,
    SiteRateHistories,
    DayExtraItems,
  ],
  daos: [WorkEntryDao, PresetDao, MemoDao, SiteDao, DayItemDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// pre-open 가드가 참조하는 코드 스키마 버전.
  ///
  /// 버전 이력 (drift_schemas/ 에 덤프 커밋, 전 버전쌍 마이그레이션 테스트):
  /// - v1 (M1): WorkEntries, Presets, DayMemos, AppSettings
  /// - v2 (M2): + Sites, SiteRateHistories, DayExtraItems
  static const int codeSchemaVersion = 2;

  @override
  int get schemaVersion => codeSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // additive-only 하드 룰: CREATE TABLE / ADD COLUMN(nullable 또는
      // 상수 default) / CREATE INDEX 만 허용. RENAME/DROP/타입 변경 금지.
      // destructive fallback은 어떤 경로에도 존재하지 않는다.
      // drift는 onUpgrade를 자동으로 트랜잭션에 감싸지 않으므로 직접 감싼다
      // — 중간에 죽어도 반쯤 적용된 스키마가 남지 않는다.
      await transaction(() async {
        if (from < 2) {
          await m.createTable(sites);
          await m.createTable(siteRateHistories);
          await m.createTable(dayExtraItems);
          await m.createIndex(idxSiteRatesSiteFrom);
          await m.createIndex(idxDayExtraItemsDate);
        }
      });
    },
    beforeOpen: (details) async {
      // WAL: 쓰기 도중 크래시에도 DB 본체를 보호한다.
      await customStatement('PRAGMA journal_mode = WAL');
      if (details.wasCreated) {
        await _seedDefaultPresets();
      }
    },
  );

  /// 시드 행의 타임스탬프는 고정 0 — 새 기기의 시드가 백업 병합(LWW)에서
  /// 사용자가 수정해 둔 프리셋(updatedAt > 0)을 절대 이기지 못하게 한다.
  /// '미수정 시드' 판정(createdAt == updatedAt)도 그대로 성립한다.
  static const int seedTimestampMillis = 0;

  Future<void> _seedDefaultPresets() async {
    await batch((b) {
      b.insertAll(presets, [
        for (final p in constructionSeedPresets)
          PresetsCompanion.insert(
            uid: p.uid,
            name: p.name,
            centiGongsu: p.centiGongsu,
            colorId: Value(p.colorId),
            sortOrder: p.sortOrder,
            createdAtMillis: seedTimestampMillis,
            updatedAtMillis: seedTimestampMillis,
          ),
      ]);
    });
  }
}
