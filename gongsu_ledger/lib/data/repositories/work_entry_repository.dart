import 'package:drift/drift.dart';

import '../../domain/uid.dart';
import '../db/app_database.dart';
import '../db/daos/work_entry_dao.dart';

/// 공수 기록 쓰기 게이트. 모든 쓰기는 여기를 거친다.
///
/// - uid/타임스탬프 부여, 값 불변식 검증(음수 금지)을 한 곳에 모은다.
/// - 프리셋 입력은 이름/색을 스냅샷으로 복사한다.
class WorkEntryRepository {
  WorkEntryRepository(this._dao);

  final WorkEntryDao _dao;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  /// 프리셋 버튼 입력. 이름/색 스냅샷 복사 — 이후 프리셋이 바뀌어도 기록 불변.
  Future<int> addFromPreset({required int dateKey, required Preset preset}) =>
      _add(
        dateKey: dateKey,
        centiGongsu: preset.centiGongsu,
        presetId: preset.id,
        labelSnapshot: preset.name,
        colorIdSnapshot: preset.colorId,
      );

  /// 직접 입력.
  Future<int> addCustom({required int dateKey, required int centiGongsu}) =>
      _add(dateKey: dateKey, centiGongsu: centiGongsu);

  Future<int> _add({
    required int dateKey,
    required int centiGongsu,
    int? presetId,
    String labelSnapshot = '',
    int colorIdSnapshot = 0,
  }) {
    _validateCenti(centiGongsu);
    final now = _now;
    return _dao.insertEntry(WorkEntriesCompanion.insert(
      uid: generateUid(),
      dateKey: dateKey,
      centiGongsu: centiGongsu,
      presetId: Value(presetId),
      labelSnapshot: Value(labelSnapshot),
      colorIdSnapshot: Value(colorIdSnapshot),
      createdAtMillis: now,
      updatedAtMillis: now,
    ));
  }

  /// 값 수정. 프리셋 기록의 값을 손으로 바꾸면 그 기록은 '직접 입력'이 된다
  /// (이름 스냅샷 해제 — "1공수" 라벨에 1.5가 붙는 거짓 표시 방지).
  /// 색 스냅샷은 유지해 달력 표시 연속성을 지킨다.
  Future<void> updateValue({required int id, required int centiGongsu}) {
    _validateCenti(centiGongsu);
    return _dao.updateFields(
      id,
      WorkEntriesCompanion(
        centiGongsu: Value(centiGongsu),
        presetId: const Value(null),
        labelSnapshot: const Value(''),
        updatedAtMillis: Value(_now),
      ),
    );
  }

  /// soft delete — UI는 반드시 '실행 취소'를 제공한다.
  Future<void> softDelete(int id) => _dao.softDelete(id, _now);

  Future<void> restore(int id) => _dao.restore(id, _now);

  void _validateCenti(int centi) {
    if (centi < 0) {
      throw ArgumentError.value(centi, 'centiGongsu', '공수는 음수가 될 수 없다');
    }
  }
}
