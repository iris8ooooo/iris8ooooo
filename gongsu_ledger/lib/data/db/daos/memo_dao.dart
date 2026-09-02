import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'memo_dao.g.dart';

@DriftAccessor(tables: [DayMemos])
class MemoDao extends DatabaseAccessor<AppDatabase> with _$MemoDaoMixin {
  MemoDao(super.db);

  /// 빈 본문 행은 tombstone(삭제 표식)이므로 null로 취급한다.
  Stream<DayMemo?> watchMemo(int dateKey) =>
      (select(dayMemos)..where((t) => t.dateKey.equals(dateKey)))
          .watchSingleOrNull()
          .map((memo) => memo == null || memo.body.isEmpty ? null : memo);

  /// 한 달 중 메모가 있는 날짜 키 집합 — 달력 셀 표시용. tombstone 제외.
  Stream<Set<int>> watchMonthMemoKeys(int ym) =>
      (selectOnly(dayMemos)
            ..addColumns([dayMemos.dateKey])
            ..where(
              dayMemos.dateKey.isBetweenValues(ym * 100 + 1, ym * 100 + 31) &
                  dayMemos.body.equals('').not(),
            ))
          .watch()
          .map((rows) => rows.map((r) => r.read(dayMemos.dateKey)!).toSet());

  /// 기간의 메모(tombstone 제외) — 확인서 PDF용.
  Future<List<DayMemo>> getRange(int fromKey, int toKey) =>
      (select(dayMemos)
            ..where(
              (t) =>
                  t.dateKey.isBetweenValues(fromKey, toKey) &
                  t.body.equals('').not(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dateKey)]))
          .get();

  /// 본문이 비면 tombstone(빈 본문 + updatedAt 갱신)으로 바꾸고,
  /// 있으면 upsert. 물리 삭제하지 않는 이유: 백업 병합(LWW)이 삭제를
  /// 인지해야 옛 백업을 붙여넣었을 때 지운 메모가 부활하지 않는다.
  Future<void> setMemo(int dateKey, String body, int nowMillis) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      await (update(dayMemos)..where((t) => t.dateKey.equals(dateKey))).write(
        DayMemosCompanion(
          body: const Value(''),
          updatedAtMillis: Value(nowMillis),
        ),
      );
      return;
    }
    await into(dayMemos).insertOnConflictUpdate(
      DayMemosCompanion.insert(
        dateKey: Value(dateKey),
        body: trimmed,
        updatedAtMillis: nowMillis,
      ),
    );
  }
}
