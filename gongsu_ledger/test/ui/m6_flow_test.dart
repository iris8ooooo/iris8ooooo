import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/domain/widget_payload.dart';
import 'package:gongsu_ledger/services/home_widget_service.dart';
import 'package:gongsu_ledger/services/purchase_service.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';
import 'package:gongsu_ledger/state/purchase_providers.dart';
import 'package:gongsu_ledger/state/widget_providers.dart';
import 'package:gongsu_ledger/ui/calendar/calendar_page.dart';
import 'package:gongsu_ledger/ui/export/report_export_page.dart';
import 'package:gongsu_ledger/ui/onboarding/onboarding_page.dart';
import 'package:gongsu_ledger/ui/pro/paywall_page.dart';
import 'package:gongsu_ledger/ui/sites/site_edit_page.dart';

class FakePurchaseService implements PurchaseService {
  final _controller = StreamController<PurchaseOutcome>.broadcast();
  Future<void> Function()? handler;
  int reconciles = 0;

  @override
  set entitlementHandler(Future<void> Function()? h) => handler = h;

  @override
  Future<void> reconcileAtStartup() async => reconciles++;
  bool available = true;
  PurchaseOutcome? onBuy = PurchaseOutcome.purchased;
  PurchaseOutcome? onRestore = PurchaseOutcome.restored;
  int buys = 0;
  int restores = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<String?> fetchPrice() async => '₩6,600';

  @override
  Stream<PurchaseOutcome> get outcomes => _controller.stream;

  @override
  Future<void> buy() async {
    buys++;
    if (onBuy != null) {
      if (onBuy == PurchaseOutcome.purchased) await handler?.call();
      _controller.add(onBuy!);
    }
  }

  @override
  Future<void> restore() async {
    restores++;
    if (onRestore != null) _controller.add(onRestore!);
  }

  @override
  void dispose() => _controller.close();
}

class FakeHomeWidgetService implements HomeWidgetService {
  final Map<String, String> saved = {};

  @override
  Future<void> saveData(Map<String, String> data) async => saved.addAll(data);

  @override
  Future<void> requestUpdate() async {}
}

/// M6 플로: 온보딩, 설정(큰글씨·화면 모드·주 시작), 프로 게이팅·구매·복원.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late MemoryLocalPrefs prefs;
  late FakePurchaseService purchase;
  late FakeHomeWidgetService widgetService;

  Widget buildApp({Map<String, String>? initialPrefs}) {
    db = AppDatabase(NativeDatabase.memory());
    prefs = MemoryLocalPrefs(initialPrefs ?? {'onboarding_done': '1'});
    purchase = FakePurchaseService();
    widgetService = FakeHomeWidgetService();
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        localPrefsProvider.overrideWithValue(prefs),
        purchaseServiceProvider.overrideWithValue(purchase),
        homeWidgetServiceProvider.overrideWithValue(widgetService),
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('온보딩', () {
    testWidgets('첫 실행은 온보딩, 조선소 선택 → 달력 + 조선소 프리셋 + 완료 저장', (tester) async {
      await tester.pumpWidget(buildApp(initialPrefs: {}));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(CalendarPage), findsNothing);

      await tester.tap(find.byKey(const ValueKey('onboard-shipyard')));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPage), findsOneWidget);
      expect(prefs.getString('onboarding_done'), '1');
      expect(prefs.getString('job_kind'), 'shipyard');
      final names = (await db.presetDao.getActive()).map((p) => p.name);
      expect(names, contains('A(0.9)'));
      expect(names, isNot(contains('1공수')));
      await unmountApp(tester);
    });

    testWidgets('온보딩 완료면 바로 달력', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.byType(CalendarPage), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('설정 → 직군 프리셋 다시 고르기 → 건설로 복귀', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '설정');
      await scrollTo(tester, find.byKey(const ValueKey('job-presets')));
      await tester.tap(find.byKey(const ValueKey('job-presets')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboard-shipyard')));
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsOneWidget); // 설정으로 돌아옴
      final names = (await db.presetDao.getActive()).map((p) => p.name);
      expect(names, contains('E잔업'));
      await unmountApp(tester);
    });
  });

  group('설정', () {
    testWidgets('글씨 크기 아주 크게 → 배율 1.3 적용, 주요 화면 오버플로 없음', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '설정');
      await tester.tap(find.byKey(const ValueKey('text-size-xlarge')));
      await tester.pumpAndSettle();
      expect(prefs.getString('text_size'), 'xlarge');
      await back(tester);

      final context = tester.element(find.byType(CalendarPage));
      expect(MediaQuery.textScalerOf(context).scale(100), closeTo(130, 0.01));

      // 큰글씨 상태로 주요 화면을 돌아본다 — 오버플로가 나면 테스트가 실패한다.
      await openMenu(tester, '정산 (기간 지정)');
      await back(tester);
      await openMenu(tester, '통계');
      await back(tester);
      await openMenu(tester, '업체(현장) 관리');
      await back(tester);
      await openMenu(tester, '백업 / 복원');
      await back(tester);
      await unmountApp(tester);
    });

    testWidgets('화면 모드 어둡게 → 다크 테마', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '설정');
      await tester.tap(find.byKey(const ValueKey('screen-mode-dark')));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('설정'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(prefs.getString('screen_mode'), 'dark');
      await unmountApp(tester);
    });

    testWidgets('주 시작 월요일 → 달력 요일 헤더가 월요일부터', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('일')).dx <
            tester.getTopLeft(find.text('월')).dx,
        true,
      );
      await openMenu(tester, '설정');
      await tester.tap(find.byKey(const ValueKey('week-start-monday')));
      await tester.pumpAndSettle();
      await back(tester);
      expect(
        tester.getTopLeft(find.text('월')).dx <
            tester.getTopLeft(find.text('일')).dx,
        true,
      );
      expect(prefs.getString('week_start'), 'monday');
      await unmountApp(tester);
    });

    testWidgets('테마 색은 프로 기능: 무료면 페이월', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '설정');
      await tester.tap(find.byKey(const ValueKey('theme-color-1')));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallPage), findsOneWidget);
      expect(find.text('프로 기능이에요: 테마 색상'), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('프로', () {
    testWidgets('무료: 업체 3개 뒤 추가는 페이월 → 구매 → 추가 가능', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      final sites = SiteRepository(db.siteDao);
      for (var i = 1; i <= 3; i++) {
        await sites.create(name: '현장$i', colorId: i);
      }
      await tester.pumpAndSettle();
      await openMenu(tester, '업체(현장) 관리');
      await tester.tap(find.text('업체 추가'));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallPage), findsOneWidget);
      expect(find.byType(SiteEditPage), findsNothing);

      await tester.tap(find.byKey(const ValueKey('buy-pro')));
      await tester.pumpAndSettle();
      expect(purchase.buys, 1);
      expect(find.text('프로가 켜졌어요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(prefs.getString('pro_unlocked'), '1');
      expect(find.byType(SiteEditPage), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('정산 → PDF 버튼: 무료면 페이월, 프로면 확인서 화면', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '정산 (기간 지정)');
      await tester.tap(find.byKey(const ValueKey('export-pdf')));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallPage), findsOneWidget);
      await back(tester);
      await back(tester);
      await unmountApp(tester);

      await tester.pumpWidget(
        buildApp(initialPrefs: {'onboarding_done': '1', 'pro_unlocked': '1'}),
      );
      await tester.pumpAndSettle();
      await openMenu(tester, '정산 (기간 지정)');
      await tester.tap(find.byKey(const ValueKey('export-pdf')));
      await tester.pumpAndSettle();
      expect(find.byType(ReportExportPage), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('이전 구매 복원 → 프로', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      await openMenu(tester, '설정');
      await scrollTo(tester, find.byKey(const ValueKey('pro-tile')));
      await tester.tap(find.byKey(const ValueKey('pro-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-pro')));
      await tester.pumpAndSettle();
      expect(purchase.restores, 1);
      expect(find.text('프로가 켜졌어요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(prefs.getString('pro_unlocked'), '1');
      await tester.pump(const Duration(seconds: 7)); // 복원 대기 타이머 소진
      await unmountApp(tester);
    });

    testWidgets('스토어 오류면 안내 문구, 프로 아님', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      purchase.onBuy = PurchaseOutcome.error;
      await openMenu(tester, '설정');
      await scrollTo(tester, find.byKey(const ValueKey('pro-tile')));
      await tester.tap(find.byKey(const ValueKey('pro-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-pro')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('paywall-message')), findsOneWidget);
      expect(prefs.getString('pro_unlocked'), isNull);
      await unmountApp(tester);
    });

    testWidgets('홈 위젯: 무료면 잠김 페이로드, 프로면 숫자', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(widgetService.saved[WidgetKeys.locked], '1');
      expect(widgetService.saved[WidgetKeys.gongsu], '');
      await unmountApp(tester);

      await tester.pumpWidget(
        buildApp(initialPrefs: {'onboarding_done': '1', 'pro_unlocked': '1'}),
      );
      await tester.pumpAndSettle();
      expect(widgetService.saved[WidgetKeys.locked], '0');
      expect(widgetService.saved[WidgetKeys.gongsu], '0');
      await unmountApp(tester);
    });
  });
}
