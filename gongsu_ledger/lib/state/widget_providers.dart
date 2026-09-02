import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/home_widget_service.dart';

/// 홈 위젯 서비스. 테스트에서는 가짜로 override.
final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => HomeWidgetPluginService(),
);
