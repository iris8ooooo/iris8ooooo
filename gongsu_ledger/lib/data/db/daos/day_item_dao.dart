import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'day_item_dao.g.dart';

/// 일 단위 부가 항목 DAO. 읽기는 [_alive]를 거친다.
@DriftAccessor(tables: [DayExtraItems])
class DayItemDao extends DatabaseAccessor<AppDatabase> with _$DayItemDaoMixin {
  DayItemDao(super.db);

  SimpleSelectStatement<$DayExtraItemsTable, DayExtraItem> _alive() =>
      select(dayExtraItems)..where((t) => t.deletedAtMillis.isNull());

  /// 한 달치 부가 항목 — 월 정산 반영용.
  Stream<List<DayExtraItem>> watchMonth(int ym) =>
      (_alive()
            ..where(
              (t) => t.dateKey.isBetweenValues(ym * 100 + 1, ym * 100 + 31),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.dateKey),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Stream<List<DayExtraItem>> watchRange(int fromKey, int toKey) =>
      (_alive()
            ..where((t) => t.dateKey.isBetweenValues(fromKey, toKey))
            ..orderBy([
              (t) => OrderingTerm.asc(t.dateKey),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Future<List<DayExtraItem>> getRange(int fromKey, int toKey) =>
      (_alive()
            ..where((t) => t.dateKey.isBetweenValues(fromKey, toKey))
            ..orderBy([
              (t) => OrderingTerm.asc(t.dateKey),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// 삭제된(soft delete) 부가항목 — '삭제된 기록' 화면용.
  Stream<List<DayExtraItem>> watchDeleted() =>
      (select(dayExtraItems)
            ..where((t) => t.deletedAtMillis.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.deletedAtMillis)]))
          .watch();

  Future<int> insertItem(DayExtraItemsCompanion item) =>
      into(dayExtraItems).insert(item);

  Future<void> updateFields(int id, DayExtraItemsCompanion changes) =>
      (update(dayExtraItems)..where((t) => t.id.equals(id))).write(changes);

  Future<void> softDelete(int id, int nowMillis) => updateFields(
    id,
    DayExtraItemsCompanion(
      deletedAtMillis: Value(nowMillis),
      updatedAtMillis: Value(nowMillis),
    ),
  );

  Future<void> restore(int id, int nowMillis) => updateFields(
    id,
    DayExtraItemsCompanion(
      deletedAtMillis: const Value(null),
      updatedAtMillis: Value(nowMillis),
    ),
  );
}
