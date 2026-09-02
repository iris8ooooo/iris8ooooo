import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appearance.dart';
import 'db_providers.dart';
import 'prefs_providers.dart';

/// 화면 설정. 첫 프레임은 prefs 에서 동기로 읽고, 변경은 prefs + AppSettings 에 함께 쓴다.
class AppearanceNotifier extends Notifier<Appearance> {
  @override
  Appearance build() {
    final prefs = ref.watch(localPrefsProvider);
    return Appearance.fromStrings(prefs.getString);
  }

  void setTextSize(TextSize v) =>
      _update(state.copyWith(textSize: v), AppearanceKeys.textSize, v.name);

  void setScreenMode(ScreenMode v) =>
      _update(state.copyWith(screenMode: v), AppearanceKeys.screenMode, v.name);

  void setWeekStart(WeekStart v) =>
      _update(state.copyWith(weekStart: v), AppearanceKeys.weekStart, v.name);

  void setThemeColor(int id) => _update(
    state.copyWith(themeColorId: id),
    AppearanceKeys.themeColor,
    '$id',
  );

  void _update(Appearance next, String key, String value) {
    state = next;
    unawaited(ref.read(localPrefsProvider).setString(key, value));
    unawaited(
      ref.read(settingsRepoProvider).set(key, value).catchError((_) {}),
    );
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);
