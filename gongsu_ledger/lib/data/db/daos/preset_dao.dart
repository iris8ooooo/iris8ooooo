import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'preset_dao.g.dart';

@DriftAccessor(tables: [Presets])
class PresetDao extends DatabaseAccessor<AppDatabase> with _$PresetDaoMixin {
  PresetDao(super.db);

  /// 보관되지 않은 프리셋. sortOrder → id 순.
  Stream<List<Preset>> watchActive() => (select(presets)
        ..where((t) => t.isArchived.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();

  Future<List<Preset>> getActive() => (select(presets)
        ..where((t) => t.isArchived.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .get();

  Future<int> insertPreset(PresetsCompanion preset) =>
      into(presets).insert(preset);

  Future<void> updateFields(int id, PresetsCompanion changes) =>
      (update(presets)..where((t) => t.id.equals(id))).write(changes);

  /// 삭제 대신 보관 — 과거 기록의 presetId 참조가 계속 유효하다.
  Future<void> archive(int id, int nowMillis) => updateFields(
      id,
      PresetsCompanion(
          isArchived: const Value(true), updatedAtMillis: Value(nowMillis)));

  /// 순서 일괄 반영. 사용자 수정 흔적(updatedAtMillis)은 남기지 않는다 —
  /// 온보딩의 "미수정 시드만 교체" 판정은 이름/값/색 수정 여부로만 한다.
  Future<void> reorder(List<int> orderedIds) => transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await updateFields(
              orderedIds[i], PresetsCompanion(sortOrder: Value(i)));
        }
      });
}
