// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_dao.dart';

// ignore_for_file: type=lint
mixin _$PresetDaoMixin on DatabaseAccessor<AppDatabase> {
  $PresetsTable get presets => attachedDatabase.presets;
  PresetDaoManager get managers => PresetDaoManager(this);
}

class PresetDaoManager {
  final _$PresetDaoMixin _db;
  PresetDaoManager(this._db);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db.attachedDatabase, _db.presets);
}
