import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'work_entry_dao.g.dart';

/// 공수 기록 DAO.
///
/// 읽기는 반드시 [_alive]를 거친다 — soft delete된 행이 월 합계·정산·위젯
/// 어디에도 새어 들어가지 않게 하는 단일 진입점이다. `select(workEntries)`를
/// 직접 쓰는 읽기 코드는 금지 (예외: 백업 내보내기 — 삭제 행 포함이 명세).
@DriftAccessor(tables: [WorkEntries])
class WorkEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WorkEntryDaoMixin {
  WorkEntryDao(super.db);

  SimpleSelectStatement<$WorkEntriesTable, WorkEntry> _alive() =>
      select(workEntries)..where((t) => t.deletedAtMillis.isNull());

  /// 한 달치 살아있는 기록. 같은 날 여러 건의 순서는 id(입력 순서) 오름차순.
  Stream<List<WorkEntry>> watchMonth(int ym) =>
      (_alive()
            ..where(
              (t) => t.dateKey.isBetweenValues(ym * 100 + 1, ym * 100 + 31),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.dateKey),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  /// 임의 기간(dateKey 양끝 포함)의 살아있는 기록 — M3 기간 정산 대비.
  Future<List<WorkEntry>> getRange(int fromKey, int toKey) =>
      (_alive()
            ..where((t) => t.dateKey.isBetweenValues(fromKey, toKey))
            ..orderBy([
              (t) => OrderingTerm.asc(t.dateKey),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  Future<WorkEntry?> getById(int id) =>
      (_alive()..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertEntry(WorkEntriesCompanion entry) =>
      into(workEntries).insert(entry);

  Future<void> updateFields(int id, WorkEntriesCompanion changes) =>
      (update(workEntries)..where((t) => t.id.equals(id))).write(changes);

  /// updatedAtMillis도 함께 올린다 — 백업 병합(LWW)이 updatedAt 비교라서
  /// 이걸 안 올리면 삭제/복원이 다른 기기로 영원히 전파되지 않는다.
  Future<void> softDelete(int id, int nowMillis) => updateFields(
    id,
    WorkEntriesCompanion(
      deletedAtMillis: Value(nowMillis),
      updatedAtMillis: Value(nowMillis),
    ),
  );

  Future<void> restore(int id, int nowMillis) => updateFields(
    id,
    WorkEntriesCompanion(
      deletedAtMillis: const Value(null),
      updatedAtMillis: Value(nowMillis),
    ),
  );
}
