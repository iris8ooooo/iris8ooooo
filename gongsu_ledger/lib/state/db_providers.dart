import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/repositories/memo_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../data/repositories/work_entry_repository.dart';

/// 앱 DB 싱글턴. 테스트에서는 in-memory DB로 override한다.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openAppConnection());
  ref.onDispose(db.close);
  return db;
});

final workEntryRepoProvider = Provider<WorkEntryRepository>(
    (ref) => WorkEntryRepository(ref.watch(databaseProvider).workEntryDao));

final presetRepoProvider = Provider<PresetRepository>(
    (ref) => PresetRepository(ref.watch(databaseProvider).presetDao));

final memoRepoProvider = Provider<MemoRepository>(
    (ref) => MemoRepository(ref.watch(databaseProvider).memoDao));
