import 'package:drift/drift.dart';

import '../../domain/uid.dart';
import '../db/app_database.dart';
import '../db/daos/day_item_dao.dart';

/// 부가 항목 종류. DB에는 안정된 문자열로 저장한다.
enum ExtraItemKind {
  allowance('allowance', '가산'),
  deduction('deduction', '공제');

  const ExtraItemKind(this.code, this.label);
  final String code;
  final String label;

  static ExtraItemKind fromCode(String code) =>
      values.firstWhere((k) => k.code == code, orElse: () => allowance);
}

/// 자주 쓰는 항목 이름 — 시트에서 한 번에 고를 수 있게.
const List<String> allowanceQuickLabels = ['일비', '식비', '숙식비', '교통비'];
const List<String> deductionQuickLabels = ['안전용품비', '가불', '식대공제'];

class DayItemRepository {
  DayItemRepository(this._dao);

  final DayItemDao _dao;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<int> add({
    required int dateKey,
    required ExtraItemKind kind,
    required String label,
    required int amountWon,
    int? siteId,
    bool isTaxable = false,
  }) {
    _validate(label, amountWon);
    final now = _now;
    return _dao.insertItem(
      DayExtraItemsCompanion.insert(
        uid: generateUid(),
        dateKey: dateKey,
        siteId: Value(siteId),
        kind: kind.code,
        label: label.trim(),
        amountWon: amountWon,
        // 공제 항목은 과세 여부가 무의미하므로 항상 false.
        isTaxable: Value(kind == ExtraItemKind.allowance && isTaxable),
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );
  }

  Future<void> update({
    required int id,
    required ExtraItemKind kind,
    required String label,
    required int amountWon,
    bool isTaxable = false,
  }) {
    _validate(label, amountWon);
    return _dao.updateFields(
      id,
      DayExtraItemsCompanion(
        kind: Value(kind.code),
        label: Value(label.trim()),
        amountWon: Value(amountWon),
        isTaxable: Value(kind == ExtraItemKind.allowance && isTaxable),
        updatedAtMillis: Value(_now),
      ),
    );
  }

  Future<void> softDelete(int id) => _dao.softDelete(id, _now);

  Future<void> restore(int id) => _dao.restore(id, _now);

  void _validate(String label, int amountWon) {
    if (label.trim().isEmpty || label.trim().length > 20) {
      throw ArgumentError.value(label, 'label', '항목 이름은 1~20자');
    }
    if (amountWon < 0) {
      throw ArgumentError.value(amountWon, 'amountWon', '금액은 0 이상');
    }
  }
}
