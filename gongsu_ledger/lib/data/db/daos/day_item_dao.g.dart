// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_item_dao.dart';

// ignore_for_file: type=lint
mixin _$DayItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayExtraItemsTable get dayExtraItems => attachedDatabase.dayExtraItems;
  DayItemDaoManager get managers => DayItemDaoManager(this);
}

class DayItemDaoManager {
  final _$DayItemDaoMixin _db;
  DayItemDaoManager(this._db);
  $$DayExtraItemsTableTableManager get dayExtraItems =>
      $$DayExtraItemsTableTableManager(_db.attachedDatabase, _db.dayExtraItems);
}
