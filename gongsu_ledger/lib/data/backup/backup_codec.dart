import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// 간이 백업 코덱 (M1 안전망 — M4 정식 백업의 축소판, 같은 봉투 규약).
///
/// 규약 (M4에서도 유지):
/// - 봉투: format/schemaVersion/exportedAtMillis + 테이블별 행 배열
/// - 내보내기는 soft delete된 행도 deletedAtMillis 그대로 포함한다
/// - 가져오기는 **병합 전용**: uid(메모는 dateKey) 기준 upsert,
///   updatedAtMillis 최신 승리. 기존 행을 지우는 경로가 없다 —
///   잘못된 파일을 붙여넣어도 데이터가 사라질 수 없다.
/// - forward-tolerant: 모르는 키는 무시, 빠진 컬럼은 기본값.
///   백업 schemaVersion이 앱 지원 범위보다 높으면 조용히 깎지 않고
///   [BackupTooNew]를 던진다 (UI: "앱을 업데이트한 뒤 복원해 주세요").
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
  const ImportResult(
      {required this.inserted, required this.updated, required this.skipped});
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
  // 기록→프리셋 연결은 로컬 autoincrement id가 아니라 uid로 내보낸다 —
  // 다른 기기에 병합될 때 id가 어긋나 엉뚱한 프리셋을 가리키는 것을 막는다.
  final presetUidById = {for (final p in presets) p.id: p.uid};
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
          'siteId': e.siteId,
          'unitRateWonOverride': e.unitRateWonOverride,
          'createdAtMillis': e.createdAtMillis,
          'updatedAtMillis': e.updatedAtMillis,
          'deletedAtMillis': e.deletedAtMillis,
        }
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
        }
    ],
    'dayMemos': [
      for (final m in memos)
        {
          'dateKey': m.dateKey,
          'body': m.body,
          'updatedAtMillis': m.updatedAtMillis,
        }
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
    // 프리셋을 먼저 병합해야 기록의 presetUid를 로컬 id로 되살릴 수 있다.
    for (final row in _rows(decoded['presets'])) {
      final uid = row['uid'];
      if (uid is! String || uid.length != 36) {
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
      final existing = await (db.select(db.presets)
            ..where((t) => t.uid.equals(uid)))
          .getSingleOrNull();
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
        await (db.update(db.presets)..where((t) => t.uid.equals(uid)))
            .write(companion);
        updated++;
      }
    }

    final presetRows = await db.select(db.presets).get();
    final presetIdByUid = {for (final p in presetRows) p.uid: p.id};

    for (final row in _rows(decoded['workEntries'])) {
      final uid = row['uid'];
      if (uid is! String || uid.length != 36) {
        skipped++;
        continue;
      }
      // 앱 내 다른 쓰기는 전부 repository 검증을 거치는데 이 경로만
      // 우회하므로, 손상·편집된 백업의 오염 행(음수 공수, 엉뚱한 날짜)이
      // 월 합계를 조용히 망가뜨리지 않게 여기서 값 불변식을 지킨다.
      final dateKey = _asInt(row['dateKey']);
      final centiGongsu = _asInt(row['centiGongsu']);
      if (dateKey == null ||
          !_isPlausibleDateKey(dateKey) ||
          centiGongsu == null ||
          centiGongsu < 0) {
        skipped++;
        continue;
      }
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(db.workEntries)
            ..where((t) => t.uid.equals(uid)))
          .getSingleOrNull();
      final presetUid = row['presetUid'];
      final companion = WorkEntriesCompanion(
        uid: Value(uid),
        dateKey: Value(dateKey),
        centiGongsu: Value(centiGongsu),
        presetId:
            Value(presetUid is String ? presetIdByUid[presetUid] : null),
        labelSnapshot: Value(row['labelSnapshot'] as String? ?? ''),
        colorIdSnapshot: Value(_asInt(row['colorIdSnapshot']) ?? 0),
        siteId: Value(_asInt(row['siteId'])),
        unitRateWonOverride: Value(_asInt(row['unitRateWonOverride'])),
        createdAtMillis: Value(_asInt(row['createdAtMillis']) ?? 0),
        updatedAtMillis: Value(incomingUpdatedAt),
        deletedAtMillis: Value(_asInt(row['deletedAtMillis'])),
      );
      if (existing == null) {
        await db.into(db.workEntries).insert(companion);
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        await (db.update(db.workEntries)
              ..where((t) => t.uid.equals(uid)))
            .write(companion);
        updated++;
      }
    }

    for (final row in _rows(decoded['dayMemos'])) {
      final dateKey = _asInt(row['dateKey']);
      if (dateKey == null || !_isPlausibleDateKey(dateKey)) {
        skipped++;
        continue;
      }
      final body = row['body'] as String? ?? '';
      final incomingUpdatedAt = _asInt(row['updatedAtMillis']) ?? 0;
      final existing = await (db.select(db.dayMemos)
            ..where((t) => t.dateKey.equals(dateKey)))
          .getSingleOrNull();
      if (existing == null) {
        // 없는 날짜의 tombstone(빈 본문)까지 만들 필요는 없다.
        if (body.isEmpty) continue;
        await db.into(db.dayMemos).insert(DayMemosCompanion.insert(
            dateKey: Value(dateKey),
            body: body,
            updatedAtMillis: incomingUpdatedAt));
        inserted++;
      } else if (incomingUpdatedAt > existing.updatedAtMillis) {
        // 빈 본문(tombstone)도 그대로 반영 — 삭제가 기기 간 전파된다.
        await (db.update(db.dayMemos)
              ..where((t) => t.dateKey.equals(dateKey)))
            .write(DayMemosCompanion(
                body: Value(body),
                updatedAtMillis: Value(incomingUpdatedAt)));
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
