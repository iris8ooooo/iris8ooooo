import '../db/daos/memo_dao.dart';

class MemoRepository {
  MemoRepository(this._dao);

  final MemoDao _dao;

  /// 빈 본문이면 메모 삭제, 아니면 upsert.
  Future<void> setMemo({required int dateKey, required String body}) =>
      _dao.setMemo(dateKey, body, DateTime.now().millisecondsSinceEpoch);
}
