import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'db_providers.dart';

/// 보관되지 않은 프리셋 목록 (sortOrder 순).
final presetsProvider = StreamProvider.autoDispose<List<Preset>>((ref) {
  ref.keepAlive(); // 입력 시트가 열릴 때 프리셋이 '뒤늦게 튀어나오지' 않게 상시 유지
  final dao = ref.watch(databaseProvider).presetDao;
  return dao.watchActive();
});
