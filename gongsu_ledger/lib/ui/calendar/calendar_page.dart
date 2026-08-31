import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/pre_open_guard.dart';
import '../../domain/date_key.dart';
import '../../domain/month_grid.dart';
import '../../state/calendar_providers.dart';
import '../backup/backup_page.dart';
import '../presets/preset_list_page.dart';
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
            tooltip: '오늘로 이동',
            icon: const Icon(Icons.today),
            onPressed: () =>
                _goToMonth(ymOfDateKey(dateKeyOf(DateTime.now()))),
          ),
          PopupMenuButton<String>(
            tooltip: '메뉴',
            onSelected: (value) {
              switch (value) {
                case 'presets':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PresetListPage()));
                case 'backup':
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupPage()));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'presets', child: Text('프리셋 관리')),
              PopupMenuItem(value: 'backup', child: Text('백업 / 복원')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            MonthSummaryCard(ym: ym),
            const _WeekdayHeader(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (page) =>
                    ref.read(visibleYmProvider.notifier).set(_ymOfPage(page)),
                itemBuilder: (context, page) => MonthView(
                  ym: _ymOfPage(page),
                  onOutsideMonthTap: _goToMonth,
                ),
              ),
            ),
          ],
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
            Icon(isDowngrade ? Icons.system_update : Icons.error_outline,
                size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              isDowngrade ? '앱 업데이트가 필요해요' : '기록을 불러오지 못했어요',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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

class _WeekdayHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          for (final weekday in weekdayOrder())
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
