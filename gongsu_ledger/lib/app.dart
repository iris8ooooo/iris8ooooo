import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/appearance.dart';
import 'state/appearance_providers.dart';
import 'state/pro_providers.dart';
import 'ui/app_theme.dart';
import 'ui/calendar/calendar_page.dart';
import 'ui/common/home_widget_syncer.dart';
import 'ui/common/purchase_syncer.dart';
import 'ui/common/snapshot_scheduler.dart';
import 'ui/onboarding/onboarding_page.dart';

class GongsuApp extends ConsumerWidget {
  const GongsuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final isPro = ref.watch(proProvider);
    final onboarded = ref.watch(onboardingDoneProvider);
    // 테마 색은 프로 기능 — 프로가 아니면 항상 기본색.
    final seed = themeColorById(isPro ? appearance.themeColorId : 0).argb;

    return MaterialApp(
      title: '공수장부',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light, seedArgb: seed),
      darkTheme: buildAppTheme(Brightness.dark, seedArgb: seed),
      themeMode: switch (appearance.screenMode) {
        ScreenMode.system => ThemeMode.system,
        ScreenMode.light => ThemeMode.light,
        ScreenMode.dark => ThemeMode.dark,
      },
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 큰글씨: 시스템 배율 × 앱 단계. 상한 1.5 — 그 위는 화면이 깨진다.
      builder: (context, child) {
        final system = MediaQuery.textScalerOf(context).scale(100) / 100;
        final scale = (system * appearance.textSize.scalePercent / 100).clamp(
          0.8,
          1.5,
        );
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: PurchaseSyncer(
        child: onboarded
            ? const SnapshotScheduler(
                child: HomeWidgetSyncer(child: CalendarPage()),
              )
            : const OnboardingPage(),
      ),
    );
  }
}
