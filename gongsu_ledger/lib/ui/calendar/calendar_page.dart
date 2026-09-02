import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/pre_open_guard.dart';
import '../../domain/date_key.dart';
import '../../domain/month_grid.dart';
import '../../state/appearance_providers.dart';
import '../../state/backup_providers.dart';
import '../../state/calendar_providers.dart';
import '../backup/backup_page.dart';
import '../presets/preset_list_page.dart';
import '../settings/settings_page.dart';
import '../settings/tax_rates_page.dart';
import '../settlement/settlement_page.dart';
import '../sites/site_list_page.dart';
import '../stats/stats_page.dart';
import 'month_summary_card.dart';
import 'month_view.dart';

/// 첫 화면: 월 달력 + 월 합계. 설치 → 앱 열기 → 바로 이 화면 (로그인 없음).
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  /// PageView 가운데 앵커. 앞뒤로 500년씩 스와이프 가능.
  static const int _anchorPage = 6000;

  late final int _anchorYm;
  late final PageController _controller;

  /// 달력 캡쳐 공유용 (월 카드 + 격자).
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _anchorYm = ymOfDateKey(dateKeyOf(DateTime.now()));
    _controller = PageController(initialPage: _anchorPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _ymOfPage(int page) => ymAddMonths(_anchorYm, page - _anchorPage);

  int _pageOfYm(int ym) => _anchorPage + ymDiff(ym, _anchorYm);

  void _goToMonth(int ym) {
    _controller.animateToPage(
      _pageOfYm(ym),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 달력 화면을 PNG로 만들어 공유 시트에 올린다 ("캡쳐 공유" 요청 다수).
  Future<void> _shareCapture() async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final ym = ref.read(visibleYmProvider);
      await ref
          .read(shareServiceProvider)
          .shareBytes(
            data.buffer.asUint8List(),
            fileName: 'gongsu-$ym.png',
            mimeType: 'image/png',
          );
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('달력 이미지를 공유하지 못했어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ym = ref.watch(visibleYmProvider);
    // DB 오픈 실패(다운그레이드 등)를 "빈 달력"으로 삼키지 않는다 —
    // 사용자는 그것을 데이터 유실로 인식한다. 명시적 안내 화면을 띄운다.
    final monthAsync = ref.watch(monthEntriesProvider(ym));
    if (monthAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('공수장부')),
        body: _DbErrorView(error: monthAsync.error!),
      );
    }
    // 이웃 달 미리 구독 — 스와이프 도착 즉시 그려지도록 캐시를 데워 둔다.
    ref.watch(monthEntriesProvider(prevYm(ym)));
    ref.watch(monthEntriesProvider(nextYm(ym)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${yearOfYm(ym)}년 ${monthOfYm(ym)}월'),
        actions: [
          IconButton(
            key: const ValueKey('capture-share'),
            tooltip: '달력 이미지 공유',
            icon: const Icon(Icons.ios_share),
            onPressed: _shareCapture,
          ),
          IconButton(
            tooltip: '오늘로 이동',
            icon: const Icon(Icons.today),
            onPressed: () => _goToMonth(ymOfDateKey(dateKeyOf(DateTime.now()))),
          ),
          PopupMenuButton<String>(
            tooltip: '메뉴',
            onSelected: (value) {
              switch (value) {
                case 'settlement':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettlementPage()),
                  );
                case 'stats':
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const StatsPage()));
                case 'tax':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TaxRatesPage()),
                  );
                case 'sites':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SiteListPage()),
                  );
                case 'presets':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PresetListPage()),
                  );
                case 'backup':
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const BackupPage()));
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settlement', child: Text('정산 (기간 지정)')),
              PopupMenuItem(value: 'stats', child: Text('통계')),
              PopupMenuItem(value: 'sites', child: Text('업체(현장) 관리')),
              PopupMenuItem(value: 'presets', child: Text('프리셋 관리')),
              PopupMenuItem(value: 'backup', child: Text('백업 / 복원')),
              PopupMenuItem(value: 'tax', child: Text('세금 · 요율 설정')),
              PopupMenuItem(value: 'settings', child: Text('설정')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RepaintBoundary(
          key: _captureKey,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                MonthSummaryCard(ym: ym),
                const _WeekdayHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (page) => ref
                        .read(visibleYmProvider.notifier)
                        .set(_ymOfPage(page)),
                    itemBuilder: (context, page) => MonthView(
                      ym: _ymOfPage(page),
                      onOutsideMonthTap: _goToMonth,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DbErrorView extends StatelessWidget {
  const _DbErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isDowngrade = error is DowngradeDetected;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDowngrade ? Icons.system_update : Icons.error_outline,
              size: 56,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isDowngrade ? '앱 업데이트가 필요해요' : '기록을 불러오지 못했어요',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isDowngrade
                  ? '이 기록은 더 새로운 버전의 앱에서 만든 것이에요.\n'
                        '앱을 최신 버전으로 업데이트하면 기록이 그대로 나타납니다.\n'
                        '기록은 안전하게 보관되어 있어요.'
                  : '기록은 기기에 안전하게 저장되어 있어요.\n'
                        '앱을 완전히 종료한 뒤 다시 열어 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends ConsumerWidget {
  const _WeekdayHeader();

  static const Map<int, String> _names = {
    DateTime.monday: '월',
    DateTime.tuesday: '화',
    DateTime.wednesday: '수',
    DateTime.thursday: '목',
    DateTime.friday: '금',
    DateTime.saturday: '토',
    DateTime.sunday: '일',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final weekStart = ref.watch(
      appearanceProvider.select((a) => a.weekStart.weekday),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          for (final weekday in weekdayOrder(weekStartWeekday: weekStart))
            Expanded(
              child: Center(
                child: Text(
                  _names[weekday]!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: switch (weekday) {
                      DateTime.sunday => scheme.error,
                      DateTime.saturday => scheme.primary,
                      _ => scheme.onSurfaceVariant,
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
