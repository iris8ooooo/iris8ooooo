// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_dao.dart';

// ignore_for_file: type=lint
mixin _$SiteDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $SiteRateHistoriesTable get siteRateHistories =>
      attachedDatabase.siteRateHistories;
  SiteDaoManager get managers => SiteDaoManager(this);
}

class SiteDaoManager {
  final _$SiteDaoMixin _db;
  SiteDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$SiteRateHistoriesTableTableManager get siteRateHistories =>
      $$SiteRateHistoriesTableTableManager(
        _db.attachedDatabase,
        _db.siteRateHistories,
      );
}
