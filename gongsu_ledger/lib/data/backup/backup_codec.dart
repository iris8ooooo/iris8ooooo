import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/tax_engine.dart';
import '../db/app_database.dart';
import '../repositories/day_item_repository.dart';

/// 간이 백업 코덱 (M1 안전망 — M4 정식 백업의 축소판, 같은 봉투 규약).
///
/// 규약 (M4에서도 유지):
/// - 봉투: format/schemaVersion/exportedAtMillis + 테이블별 행 배열
/// - 내보내기는 soft delete된 행도 deletedAtMillis 그대로 포함한다
/// - 가져오기는 **병합 전용**: uid(메모는 dateKey) 기준 upsert,
///   updatedAtMillis 최신 승리. 기존 행을 지우는 경로가 없다 —
///   잘못된 파일을 붙여넣어도 데이터가 사라질 수 없다.
/// - 행 간 참조(기록→프리셋/업체, 이력→업체, 항목→업체)는 로컬 id가 아니라
///   uid로 내보내고 가져올 때 재매핑한다 — 기기 간 id 어긋남 방지.
/// - forward-tolerant: 모르는 키는 무시, 빠진 컬럼은 기본값.
///   백업 schemaVersion이 앱 지원 범위보다 높으면 조용히 깎지 않고
///   [BackupTooNew]를 던진다 (UI: "앱을 업데이트한 뒤 복원해 주세요").
/// - 값 불변식(음수 공수·금액, 비정상 날짜, 빈 이름)을 위반한 행은 건너뛰고
///   skipped 로 보고한다 — 이 경로만 repository 검증을 우회하기 때문.
const String backupFormatTag = 'gongsu_ledger_backup';

class BackupTooNew implements Exception {
  BackupTooNew(this.backupVersion);
  final int backupVersion;
}

class BackupFormatError implements Exception {
  BackupFormatError(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatError: $message';
}

class ImportResult {
  const ImportResult({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });
  final int inserted;
  final int updated;

  /// 값 불변식 위반(음수 공수, 잘못된 날짜 등)으로 건너뛴 행 수.
  /// 0이 아니면 UI가 사용자에게 알린다.
  final int skipped;
}

/// yyyyMMdd 정수가 그럴듯한 날짜인지 검사 (2000~2100년).
bool _isPlausibleDateKey(int key) {
  final year = key ~/ 10000;
  final month = (key % 10000) ~/ 100;
  final day = key % 100;
  return year >= 2000 &&
      year <= 2100 &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= 31;
}

Future<String> exportBackupJson(AppDatabase db) async {
  // 백업은 삭제 행 포함이 명세 — DAO의 alive 필터를 일부러 거치지 않는
  // 유일한 읽기 경로다.
  final entries = await db.select(db.workEntries).get();
  final presets = await db.select(db.presets).get();
  final memos = await db.select(db.dayMemos).get();
  final sites = await db.select(db.sites).get();
  final rates = await db.select(db.siteRateHistories).get();
  final items = await db.select(db.dayExtraItems).get();
  final presetUidById = {for (final p in presets) p.id: p.uid};
  final siteUidById = {for (final s in sites) s.id: s.uid};

  return jsonEncode({
    'format': backupFormatTag,
    'schemaVersion': AppDatabase.codeSchemaVersion,
    'exportedAtMillis': DateTime.now().millisecondsSinceEpoch,
    'workEntries': [
      for (final e in entries)
        {
          'uid': e.uid,
          'dateKey': e.dateKey,
          'centiGongsu': e.centiGongsu,
          'presetUid': e.presetId == null ? null : presetUidById[e.presetId],
          'labelSnapshot': e.labelSnapshot,
          'colorIdSnapshot': e.colorIdSnapshot,
          'siteUid': e.siteId == null ? null : siteUidById[e.siteId],
          'unitRateWonOverride': e.unitRateWonOverride,
          'createdAtMillis': e.createdAtMillis,
          'updatedAtMillis': e.updatedAtMillis,
          'deletedAtMillis': e.deletedAtMillis,
        },
    ],
    'presets': [
      for (final p in presets)
        {
          'uid': p.uid,
          'name': p.name,
          'centiGongsu': p.centiGongsu,
          'colorId': p.colorId,
          'sortOrder': p.sortOrder,
          'isArchived': p.isArchived,
          'createdAtMillis': p.createdAtMillis,
          'updatedAtMillis': p.updatedAtMillis,
        },
    ],
    'dayMemos': [
      for (final m in memos)
        {
          'dateKey': m.dateKey,
          'body': m.body,
          'updatedAtMillis': m.updatedAtMillis,
        },
    ],
    'sites': [
      for (final s in sites)
        {
          'uid': s.uid,
          'name': s.name,
          'colorId': s.colorId,
          'sortOrder': s.sortOrder,
          'isArchived': s.isArchived,
          'createdAtMillis': s.createdAtMillis,
          'updatedAtMillis': s.updatedAtMillis,
          'taxMode': s.taxMode,
          'taxOptionsJson': s.taxOptionsJson,
        },
    ],
    'siteRateHistories': [
      for (final r in rates)
        {
          'uid': r.uid,
          'siteUid': siteUidById[r.siteId],
          'effectiveFromDateKey': r.effectiveFromDateKey,
          'dailyRateWon': r.dailyRateWon,
          'createdAtMillis': r.createdAtMillis,
          'updatedAtMillis': r.updatedAtMillis,
          'deletedAtMillis': r.deletedAtMillis,
        },
    ],
    'dayExtraItems': [
      for (final it in items)
        {
          'uid': it.uid,
          'dateKey': it.dateKey,
          'siteUid': it.siteId == null ? null : siteUidById[it.siteId],
          'kind': it.kind,
          'label': it.label,
          'amountWon': it.amountWon,
          'isTaxable': it.isTaxable,
          'createdAtMillis': it.createdAtMillis,
          'updatedAtMillis': it.updatedAtMillis,
          'deletedAtMillis': it.deletedAtMillis,
        },
    ],
  });
}

Future<ImportResult> importBackupJson(AppDatabase db, String json) async {
  Object? decodedRaw;
  try {
    decodedRaw = jsonDecode(json.trim());
  } on FormatException {
    throw BackupFormatError('JSON이 아님');
  }
  final decoded = decodedRaw;
  if (decoded is! Map<String, Object?>) {
    throw BackupFormatError('봉투 형식이 아님');
  }
  if (decoded['format'] != backupFormatTag) {
    throw BackupFormatError('공수장부 백업 데이터가 아님');
  }
  final version = decoded['schemaVersion'];
  if (version is! int) throw BackupFormatError('schemaVersion 없음');
  if (version > AppDatabase.codeSchemaVersion) throw BackupTooNew(version);

  var inserted = 0;
  var updated = 0;
  var skipped = 0;

  await db.transaction(() async {
    // ── 업체 (기록/이력/항목이 참조하므로 가장 먼저) ──────────────
    for (final row in _rows(decoded['sites'])) {
      final uid = _uid(row);
      if (uid == null) {
        skipped++;
        continue;
      }
      final name = row['name'] as String? ?? '';
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.sites,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      final companion = SitesCompanion(
        uid: Value(uid),
        name: Value(name),
        colorId: Value(_asInt(row['colorId']) ?? 0),
        sortOrder: Value(_asInt(row['sortOrder']) ?? 0),
        isArchived: Value(row['isArchived'] as bool? ?? false),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
        // v2 백업에는 없는 키 — 기본 'none'. 모르는 코드도 'none'으로.
        taxMode: Value(TaxMode.fromCode(row['taxMode'] as String?).code),
        taxOptionsJson: Value(row['taxOptionsJson'] as String?),
      );
      if (existing == null) {
        await db.into(db.sites).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(
          db.sites,
        )..where((t) => t.uid.equals(uid))).write(companion);
        updated++;
      }
    }
    final siteRows = await db.select(db.sites).get();
    final siteIdByUid = {for (final s in siteRows) s.uid: s.id};

    // ── 프리셋 ───────────────────────────────────────────────
    for (final row in _rows(decoded['presets'])) {
      final uid = _uid(row);
      if (uid == null) {
        skipped++;
        continue;
      }
      final presetCenti = _asInt(row['centiGongsu']);
      final presetName = row['name'] as String? ?? '';
      if (presetCenti == null || presetCenti < 0 || presetName.isEmpty) {
        skipped++;
        continue;
      }
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.presets,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      final companion = PresetsCompanion(
        uid: Value(uid),
        name: Value(presetName),
        centiGongsu: Value(presetCenti),
        colorId: Value(_asInt(row['colorId']) ?? 0),
        sortOrder: Value(_asInt(row['sortOrder']) ?? 0),
        isArchived: Value(row['isArchived'] as bool? ?? false),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
      );
      if (existing == null) {
        await db.into(db.presets).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(
          db.presets,
        )..where((t) => t.uid.equals(uid))).write(companion);
        updated++;
      }
    }
    final presetRows = await db.select(db.presets).get();
    final presetIdByUid = {for (final p in presetRows) p.uid: p.id};

    // ── 기록 ─────────────────────────────────────────────────
    for (final row in _rows(decoded['workEntries'])) {
      final uid = _uid(row);
      if (uid == null) {
        skipped++;
        continue;
      }
      final dateKey = _asInt(row['dateKey']);
      final centiGongsu = _asInt(row['centiGongsu']);
      final override = _asInt(row['unitRateWonOverride']);
      if (dateKey == null ||
          !_isPlausibleDateKey(dateKey) ||
          centiGongsu == null ||
          centiGongsu < 0 ||
          (override != null && override < 0)) {
        skipped++;
        continue;
      }
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.workEntries,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      final presetUid = row['presetUid'];
      final siteUid = row['siteUid'];
      final companion = WorkEntriesCompanion(
        uid: Value(uid),
        dateKey: Value(dateKey),
        centiGongsu: Value(centiGongsu),
        presetId: Value(presetUid is String ? presetIdByUid[presetUid] : null),
        labelSnapshot: Value(row['labelSnapshot'] as String? ?? ''),
        colorIdSnapshot: Value(_asInt(row['colorIdSnapshot']) ?? 0),
        siteId: Value(siteUid is String ? siteIdByUid[siteUid] : null),
        unitRateWonOverride: Value(override),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
        deletedAtMillis: Value(_asInt(row['deletedAtMillis'])),
      );
      if (existing == null) {
        await db.into(db.workEntries).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(
          db.workEntries,
        )..where((t) => t.uid.equals(uid))).write(companion);
        updated++;
      }
    }

    // ── 단가 이력 (업체 uid가 반드시 풀려야 한다) ─────────────────
    for (final row in _rows(decoded['siteRateHistories'])) {
      final uid = _uid(row);
      final siteUid = row['siteUid'];
      final siteId = siteUid is String ? siteIdByUid[siteUid] : null;
      final effectiveFrom = _asInt(row['effectiveFromDateKey']);
      final rate = _asInt(row['dailyRateWon']);
      if (uid == null ||
          siteId == null ||
          effectiveFrom == null ||
          !_isPlausibleDateKey(effectiveFrom) ||
          rate == null ||
          rate < 0) {
        skipped++;
        continue;
      }
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.siteRateHistories,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      final companion = SiteRateHistoriesCompanion(
        uid: Value(uid),
        siteId: Value(siteId),
        effectiveFromDateKey: Value(effectiveFrom),
        dailyRateWon: Value(rate),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
        deletedAtMillis: Value(_asInt(row['deletedAtMillis'])),
      );
      if (existing == null) {
        await db.into(db.siteRateHistories).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(
          db.siteRateHistories,
        )..where((t) => t.uid.equals(uid))).write(companion);
        updated++;
      }
    }

    // ── 부가 항목 ─────────────────────────────────────────────
    for (final row in _rows(decoded['dayExtraItems'])) {
      final uid = _uid(row);
      final dateKey = _asInt(row['dateKey']);
      final amount = _asInt(row['amountWon']);
      final label = row['label'] as String? ?? '';
      final kind = row['kind'] as String? ?? '';
      final validKind = ExtraItemKind.values.any((k) => k.code == kind);
      if (uid == null ||
          dateKey == null ||
          !_isPlausibleDateKey(dateKey) ||
          amount == null ||
          amount < 0 ||
          label.isEmpty ||
          !validKind) {
        skipped++;
        continue;
      }
      final siteUid = row['siteUid'];
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.dayExtraItems,
      )..where((t) => t.uid.equals(uid))).getSingleOrNull();
      final companion = DayExtraItemsCompanion(
        uid: Value(uid),
        dateKey: Value(dateKey),
        siteId: Value(siteUid is String ? siteIdByUid[siteUid] : null),
        kind: Value(kind),
        label: Value(label),
        amountWon: Value(amount),
        isTaxable: Value(row['isTaxable'] as bool? ?? false),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
        deletedAtMillis: Value(_asInt(row['deletedAtMillis'])),
      );
      if (existing == null) {
        await db.into(db.dayExtraItems).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(
          db.dayExtraItems,
        )..where((t) => t.uid.equals(uid))).write(companion);
        updated++;
      }
    }

    // ── 메모 ─────────────────────────────────────────────────
    for (final row in _rows(decoded['dayMemos'])) {
      final dateKey = _asInt(row['dateKey']);
      if (dateKey == null || !_isPlausibleDateKey(dateKey)) {
        skipped++;
        continue;
      }
      final body = row['body'] as String? ?? '';
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(
        db.dayMemos,
      )..where((t) => t.dateKey.equals(dateKey))).getSingleOrNull();
      if (existing == null) {
        // 없는 날짜의 tombstone(빈 본문)까지 만들 필요는 없다.
        if (body.isEmpty) continue;
        await db
            .into(db.dayMemos)
            .insert(
              DayMemosCompanion.insert(
                dateKey: Value(dateKey),
                body: body,
                updatedAtMillis: incomingUpdatedAt,
              ),
            );
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        // 빈 본문(tombstone)도 그대로 반영 — 삭제가 기기 간 전파된다.
        await (db.update(
          db.dayMemos,
        )..where((t) => t.dateKey.equals(dateKey))).write(
          DayMemosCompanion(
            body: Value(body),
            updatedAtMillis: Value(incomingUpdatedAt),
          ),
        );
        updated++;
      }
    }
  });

  return ImportResult(inserted: inserted, updated: updated, skipped: skipped);
}

Iterable<Map<String, Object?>> _rows(Object? value) sync* {
  if (value is! List) return;
  for (final row in value) {
    if (row is Map<String, Object?>) yield row;
  }
}

int? _asInt(Object? v) => v is int ? v : null;

String? _uid(Map<String, Object?> row) {
  final uid = row['uid'];
  return uid is String && uid.length == 36 ? uid : null;
}
