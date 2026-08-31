import 'package:drift/drift.dart';

import '../../domain/marker_palette.dart';
import '../../domain/uid.dart';
import '../db/app_database.dart';
import '../db/daos/preset_dao.dart';

class PresetRepository {
  PresetRepository(this._dao);

  final PresetDao _dao;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<int> create({
    required String name,
    required int centiGongsu,
    required int colorId,
  }) async {
    _validate(name, centiGongsu, colorId);
    final existing = await _dao.getActive();
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final now = _now;
    return _dao.insertPreset(PresetsCompanion.insert(
      uid: generateUid(),
      name: name.trim(),
      centiGongsu: centiGongsu,
      colorId: Value(colorId),
      sortOrder: nextOrder,
      createdAtMillis: now,
      updatedAtMillis: now,
    ));
  }

  /// 이름/값/색 수정. updatedAtMillis 갱신이 "사용자가 손댄 프리셋" 표식이
  /// 된다 (M6 온보딩의 미수정 시드 교체 판정 기준).
  Future<void> update({
    required int id,
    required String name,
    required int centiGongsu,
    required int colorId,
  }) {
    _validate(name, centiGongsu, colorId);
    return _dao.updateFields(
      id,
      PresetsCompanion(
        name: Value(name.trim()),
        centiGongsu: Value(centiGongsu),
        colorId: Value(colorId),
        updatedAtMillis: Value(_now),
      ),
    );
  }

  /// 삭제 대신 보관. 과거 기록 표시는 스냅샷 덕분에 그대로 유지된다.
  Future<void> archive(int id) => _dao.archive(id, _now);

  Future<void> reorder(List<int> orderedIds) =>
      _dao.reorder(orderedIds, _now);

  void _validate(String name, int centi, int colorId) {
    if (name.trim().isEmpty || name.trim().length > 20) {
      throw ArgumentError.value(name, 'name', '이름은 1~20자');
    }
    if (centi < 0) {
      throw ArgumentError.value(centi, 'centiGongsu', '공수는 음수가 될 수 없다');
    }
    if (colorId < 0 || colorId >= MarkerPalette.entries.length) {
      throw ArgumentError.value(colorId, 'colorId', '팔레트 범위 밖');
    }
  }
}
