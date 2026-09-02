import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/repositories/day_item_repository.dart';
import '../data/repositories/memo_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/site_repository.dart';
import '../data/repositories/work_entry_repository.dart';

/// 앱 DB 싱글턴. 테스트에서는 in-memory DB로 override한다.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openAppConnection());
  ref.onDispose(db.close);
  return db;
});

final workEntryRepoProvider = Provider<WorkEntryRepository>(
  (ref) => WorkEntryRepository(ref.watch(databaseProvider).workEntryDao),
);

final presetRepoProvider = Provider<PresetRepository>(
  (ref) => PresetRepository(ref.watch(databaseProvider).presetDao),
);

final memoRepoProvider = Provider<MemoRepository>(
  (ref) => MemoRepository(ref.watch(databaseProvider).memoDao),
);

final siteRepoProvider = Provider<SiteRepository>(
  (ref) => SiteRepository(ref.watch(databaseProvider).siteDao),
);

final dayItemRepoProvider = Provider<DayItemRepository>(
  (ref) => DayItemRepository(ref.watch(databaseProvider).dayItemDao),
);

final settingsRepoProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
