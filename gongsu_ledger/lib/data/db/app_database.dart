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
  /// - v3 (M3): Sites + taxMode, taxOptionsJson (ADD COLUMN)
  static const int codeSchemaVersion = 3;

  @override
  int get schemaVersion => codeSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // 생성 + 시드 + 버전 기록을 한 트랜잭션으로 — 도중에 죽어도 다음 실행이
      // 처음부터 깨끗하게 다시 만든다 (반쯤 만들어진 DB가 남지 않는다).
      await transaction(() async {
        await m.createAll();
        await _seedDefaultPresets();
        await customStatement('PRAGMA user_version = $codeSchemaVersion');
      });
    },
    onUpgrade: (m, from, to) async {
      // additive-only 하드 룰: CREATE TABLE / ADD COLUMN(nullable 또는
      // 상수 default) / CREATE INDEX 만 허용. RENAME/DROP/타입 변경 금지.
      // destructive fallback은 어떤 경로에도 존재하지 않는다.
      //
      // 재시도 안전: drift는 user_version을 beforeOpen 뒤에 따로 쓴다. 그
      // 사이에 죽으면 다음 실행이 같은 업그레이드를 다시 돌리므로, 모든 DDL은
      // "이미 있으면 건너뜀"이어야 하고 버전은 여기 트랜잭션 안에서 함께 쓴다.
      await transaction(() async {
        if (from < 2) {
          await m.createTable(sites); // CREATE TABLE IF NOT EXISTS
          await m.createTable(siteRateHistories);
          await m.createTable(dayExtraItems);
          await _createIndexIfMissing(idxSiteRatesSiteFrom);
          await _createIndexIfMissing(idxDayExtraItemsDate);
        }
        // createTable은 항상 "현재(v3) 정의"로 만들므로, v1에서 올 때는 위에서
        // 이미 새 컬럼이 포함된다. ADD COLUMN은 v2 DB에만, 없을 때만 적용한다.
        if (from >= 2 && from < 3) {
          if (!await _hasColumn('sites', 'tax_mode')) {
            await m.addColumn(sites, sites.taxMode);
          }
          if (!await _hasColumn('sites', 'tax_options_json')) {
            await m.addColumn(sites, sites.taxOptionsJson);
          }
        }
        await customStatement('PRAGMA user_version = $to');
      });
    },
    beforeOpen: (details) async {
      // WAL: 쓰기 도중 크래시에도 DB 본체를 보호한다.
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
  }

  Future<void> _createIndexIfMissing(Index index) {
    final stmt =
        index.createStatementsByDialect[SqlDialect.sqlite] ??
        index.createStatementsByDialect.values.first;
    return customStatement(
      stmt.replaceFirst(
        RegExp(r'^CREATE INDEX', caseSensitive: false),
        'CREATE INDEX IF NOT EXISTS',
      ),
    );
  }

  /// 시드 행의 타임스탬프는 고정 0 — 새 기기의 시드가 백업 병합(LWW)에서
  /// 사용자가 수정해 둔 프리셋(updatedAt > 0)을 절대 이기지 못하게 한다.
  /// '미수정 시드' 판정(createdAt == updatedAt)도 그대로 성립한다.
  static const int seedTimestampMillis = 0;

  Future<void> _seedDefaultPresets() async {
    await batch((b) {
      // insertOrIgnore: 재시도 시 고정 uid 충돌로 죽지 않는다.
      b.insertAll(mode: InsertMode.insertOrIgnore, presets, [
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
