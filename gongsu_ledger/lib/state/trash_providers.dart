import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'db_providers.dart';

/// 삭제된(soft delete) 공수 기록 — 최근 삭제 먼저.
final deletedEntriesProvider = StreamProvider.autoDispose<List<WorkEntry>>(
  (ref) => ref.watch(databaseProvider).workEntryDao.watchDeleted(),
);

/// 삭제된 부가항목.
final deletedItemsProvider = StreamProvider.autoDispose<List<DayExtraItem>>(
  (ref) => ref.watch(databaseProvider).dayItemDao.watchDeleted(),
);
