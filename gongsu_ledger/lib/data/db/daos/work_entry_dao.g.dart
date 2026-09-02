// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkEntriesTable get workEntries => attachedDatabase.workEntries;
  WorkEntryDaoManager get managers => WorkEntryDaoManager(this);
}

class WorkEntryDaoManager {
  final _$WorkEntryDaoMixin _db;
  WorkEntryDaoManager(this._db);
  $$WorkEntriesTableTableManager get workEntries =>
      $$WorkEntriesTableTableManager(_db.attachedDatabase, _db.workEntries);
}
