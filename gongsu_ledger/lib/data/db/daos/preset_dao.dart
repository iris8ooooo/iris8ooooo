import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'preset_dao.g.dart';

@DriftAccessor(tables: [Presets])
class PresetDao extends DatabaseAccessor<AppDatabase> with _$PresetDaoMixin {
  PresetDao(super.db);

  /// 보관되지 않은 프리셋. sortOrder → id 순.
  Stream<List<Preset>> watchActive() =>
      (select(presets)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<List<Preset>> getActive() =>
      (select(presets)
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
      isArchived: const Value(true),
      updatedAtMillis: Value(nowMillis),
    ),
  );

  /// 순서 일괄 반영. updatedAtMillis도 올린다 — 백업 병합(LWW)이 updatedAt
  /// 비교라서 안 올리면 순서 변경이 다른 기기로 영원히 전파되지 않는다.
  /// 부수 효과로 순서를 바꾼 시드 프리셋은 '사용자 수정'으로 취급되어
  /// M6 온보딩 직군 교체 대상에서 빠진다 — 사용자 의도를 지우지 않는
  /// 안전한 방향이다.
  Future<void> reorder(List<int> orderedIds, int nowMillis) =>
      transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await updateFields(
            orderedIds[i],
            PresetsCompanion(
              sortOrder: Value(i),
              updatedAtMillis: Value(nowMillis),
            ),
          );
        }
      });
}
