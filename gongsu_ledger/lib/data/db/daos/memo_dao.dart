import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'memo_dao.g.dart';

@DriftAccessor(tables: [DayMemos])
class MemoDao extends DatabaseAccessor<AppDatabase> with _$MemoDaoMixin {
  MemoDao(super.db);

  Stream<DayMemo?> watchMemo(int dateKey) =>
      (select(dayMemos)..where((t) => t.dateKey.equals(dateKey)))
          .watchSingleOrNull();

  /// 한 달 중 메모가 있는 날짜 키 집합 — 달력 셀 표시용.
  Stream<Set<int>> watchMonthMemoKeys(int ym) => (selectOnly(dayMemos)
        ..addColumns([dayMemos.dateKey])
        ..where(dayMemos.dateKey
            .isBetweenValues(ym * 100 + 1, ym * 100 + 31)))
      .watch()
      .map((rows) =>
          rows.map((r) => r.read(dayMemos.dateKey)!).toSet());

  /// 본문이 비면 행을 지우고, 있으면 upsert.
  Future<void> setMemo(int dateKey, String body, int nowMillis) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      await (delete(dayMemos)..where((t) => t.dateKey.equals(dateKey))).go();
      return;
    }
    await into(dayMemos).insertOnConflictUpdate(DayMemosCompanion.insert(
        dateKey: Value(dateKey), body: trimmed, updatedAtMillis: nowMillis));
  }
}
