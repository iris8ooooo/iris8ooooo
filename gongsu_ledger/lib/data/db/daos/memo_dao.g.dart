// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayMemosTable get dayMemos => attachedDatabase.dayMemos;
  MemoDaoManager get managers => MemoDaoManager(this);
}

class MemoDaoManager {
  final _$MemoDaoMixin _db;
  MemoDaoManager(this._db);
  $$DayMemosTableTableManager get dayMemos =>
      $$DayMemosTableTableManager(_db.attachedDatabase, _db.dayMemos);
}
