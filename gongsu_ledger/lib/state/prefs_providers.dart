import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_prefs.dart';

/// 경량 동기 저장소. main()이 shared_preferences 구현으로 override 한다.
/// override 가 없으면(테스트) 메모리 구현.
final localPrefsProvider = Provider<LocalPrefs>((ref) => MemoryLocalPrefs());
