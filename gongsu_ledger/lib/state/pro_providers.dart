import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import 'db_providers.dart';
import 'prefs_providers.dart';

/// prefs 와 AppSettings 에 같은 키로 '1'/'0' 을 쓰는 불리언 플래그.
abstract class _FlagNotifier extends Notifier<bool> {
  String get key;

  @override
  bool build() => ref.watch(localPrefsProvider).getString(key) == '1';

  Future<void> set(bool value) async {
    state = value;
    final raw = value ? '1' : '0';
    await ref.read(localPrefsProvider).setString(key, raw);
    unawaited(ref.read(settingsRepoProvider).set(key, raw).catchError((_) {}));
  }
}

/// 프로(일회성 구매) 잠금 해제 여부.
class ProNotifier extends _FlagNotifier {
  @override
  String get key => SettingsRepository.keyProUnlocked;

  Future<void> unlock() => set(true);
}

final proProvider = NotifierProvider<ProNotifier, bool>(ProNotifier.new);

/// 온보딩(직군 선택) 완료 여부 — 첫 프레임에서 홈/온보딩 분기.
class OnboardingNotifier extends _FlagNotifier {
  @override
  String get key => SettingsRepository.keyOnboardingDone;

  Future<void> markDone() => set(true);
}

final onboardingDoneProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
