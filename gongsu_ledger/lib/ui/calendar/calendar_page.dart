import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/pre_open_guard.dart';
import '../../data/db/connection.dart';
import '../../data/db/db_rescue.dart';
import '../../state/db_providers.dart';
import '../../domain/date_key.dart';
import '../../domain/korean_holidays.dart';
import '../../domain/month_grid.dart';
import '../../domain/marker_palette.dart';
import '../../domain/rate_resolver.dart';
import '../../state/appearance_providers.dart';
import '../../state/backup_providers.dart';
import '../../state/calendar_providers.dart';
import '../../state/site_providers.dart';
import '../app_theme.dart';
import '../common/won_format.dart';
import '../home/ink_nav_bar.dart';
import 'month_hero.dart';
import 'month_view.dart';
import '../../app_info.dart';
import '../common/app_icons.dart';

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
    final target = _pageOfYm(ym);
    final current = _controller.page?.round() ?? _anchorPage;
    // 먼 달로는 바로 점프 — 중간 달을 전부 구독하며 스크롤하지 않는다.
    if ((target - current).abs() > 2) {
      _controller.jumpToPage(target);
      return;
    }
    _controller.animateToPage(
      target,
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
        appBar: AppBar(title: const Text(kAppName)),
        body: _DbErrorView(error: monthAsync.error!),
      );
    }
    // 이웃 달 미리 구독 — 스와이프 도착 즉시 그려지도록 캐시를 데워 둔다.
    ref.watch(monthEntriesProvider(prevYm(ym)));
    ref.watch(monthEntriesProvider(nextYm(ym)));

    final c = context.colors;
    return Scaffold(
      bottomNavigationBar: const NavSpacer(),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // 캡쳐 공유 범위: 제목·요약·범례·격자 (오른쪽 위 버튼은 제외).
            RepaintBoundary(
              key: _captureKey,
              child: ColoredBox(
                color: c.paper,
                child: Column(
                  children: [
                    _MonthTitle(ym: ym),
                    MonthHero(ym: ym),
                    _LegendRow(ym: ym),
                    const _WeekdayHeader(),
                    // 격자는 남는 높이를 쓰되 칸이 시안(62px)보다 길어지지
                    // 않게 상한을 두고, 업체 범례는 격자 바로 아래에 붙인다.
                    Expanded(
                      child: Column(
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: MonthView.maxHeight,
                              ),
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
                          ),
                          _SiteLegend(ym: ym),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('capture-share'),
                    tooltip: '달력 이미지 공유',
                    icon: const Icon(AppIcons.share),
                    onPressed: _shareCapture,
                  ),
                  IconButton(
                    tooltip: '오늘로 이동',
                    icon: const Icon(AppIcons.today),
                    onPressed: () =>
                        _goToMonth(ymOfDateKey(dateKeyOf(DateTime.now()))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "9월  2026" — 달 이름은 명조(Song Myung), 연도는 작은 본문 글자.
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      // 오른쪽은 공유·오늘 버튼 자리.
      padding: const EdgeInsets.fromLTRB(24, 6, 110, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${monthOfYm(ym)}월',
            key: const ValueKey('month-title'),
            style: AppFonts.displayStyle(size: 44, color: c.text),
          ),
          const SizedBox(width: 10),
          Text(
            '${yearOfYm(ym)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 농도 범례(왼쪽) + 이번 달 공휴일 요약(오른쪽, 빨강).
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasData = koreanHolidayYears.contains(yearOfYm(ym));
    final summary = holidaySummary(ym);
    final holidayText = !hasData
        ? '공휴일 정보 없음 · 앱 업데이트 필요'
        : summary.isEmpty
        ? '공휴일 없음'
        : summary;
    final swatchLabel = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: c.muted,
    );
    Widget swatch(String label, Color color) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: swatchLabel),
          const SizedBox(width: 4),
          Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Semantics(
            label: '공수 농도 범례',
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatch('0.5', c.tint05),
                  swatch('1', c.tint10),
                  swatch('1.5', c.tint15),
                  swatch('2+', c.tint20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  holidayText,
                  key: const ValueKey('holiday-summary'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: hasData && summary.isNotEmpty ? c.red : c.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 격자 아래 업체 범례 — 색 점 + 이름 + 이 달 말일 기준 단가, 메모 네모.
/// 업체도 메모도 없으면 자리 자체를 비운다.
class _SiteLegend extends ConsumerWidget {
  const _SiteLegend({required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final sites = ref.watch(sitesProvider).valueOrNull ?? const [];
    final hasMemo =
        (ref.watch(monthMemoKeysProvider(ym)).valueOrNull ?? const <int>{})
            .isNotEmpty;
    if (sites.isEmpty && !hasMemo) return const SizedBox(height: 4);
    final rates = ref.watch(allRatesProvider).valueOrNull ?? const [];
    final histories = [
      for (final r in rates)
        (
          siteId: r.siteId,
          effectiveFromDateKey: r.effectiveFromDateKey,
          dailyRateWon: r.dailyRateWon,
        ),
    ];
    final monthEndKey = ym * 100 + daysInMonth(ym);
    final brightness = Theme.of(context).brightness;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: c.muted,
    );
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [mark, const SizedBox(width: 5), Text(label, style: style)],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (final site in sites)
            item(
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MarkerPalette.colorOf(
                    site.colorId,
                    brightness: brightness,
                  ),
                ),
              ),
              switch (resolveSiteRateWon(
                histories: histories,
                siteId: site.id,
                dateKey: monthEndKey,
              )) {
                null => site.name,
                final won => '${site.name} ${formatWon(won)}',
              },
            ),
          if (hasMemo)
            item(
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.text,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              '메모',
            ),
        ],
      ),
    );
  }
}

class _DbErrorView extends ConsumerStatefulWidget {
  const _DbErrorView({required this.error});

  final Object error;

  @override
  ConsumerState<_DbErrorView> createState() => _DbErrorViewState();
}

class _DbErrorViewState extends ConsumerState<_DbErrorView> {
  bool _busy = false;

  Object get error => widget.error;

  void _retry() => ref.invalidate(databaseProvider);

  /// 열리지 않는 DB 파일을 옆으로 치워 두고(삭제 안 함) 새 DB 로 시작한 뒤
  /// 최근 자동 스냅샷을 병합한다 — 기록 파일이 깨졌을 때의 마지막 구조 경로.
  Future<void> _rescue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 복구'),
        content: const Text(
          '열리지 않는 기록 파일을 지우지 않고 옆으로 치워 둔 뒤, '
          '새로 시작해서 최근 자동 백업(스냅샷)을 합칩니다.\n'
          '치워 둔 파일은 기기 안에 그대로 남아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복구 시작'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    String message;
    try {
      await quarantineDatabaseFiles(await appDatabaseDirectory());
      ref.invalidate(databaseProvider);
      final db = ref.read(databaseProvider);
      final snapshots = ref.read(snapshotServiceProvider);
      final list = await snapshots.list();
      if (list.isEmpty) {
        message = '새 기록으로 시작했어요. 되살릴 자동 백업은 없었습니다.';
      } else {
        final result = await snapshots.restore(db, list.first);
        message =
            '최근 자동 백업(${list.first.dateKey})에서 '
            '${result.inserted}건을 되살렸어요.';
      }
    } catch (e) {
      message = '복구하지 못했어요. 백업 텍스트나 파일이 있다면 설정 → 백업 / 복원에서 붙여넣어 주세요.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

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
              isDowngrade ? AppIcons.update : AppIcons.error,
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
            if (!isDowngrade) ...[
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('db-retry'),
                onPressed: _busy ? null : _retry,
                child: const Text('다시 시도'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('db-rescue'),
                onPressed: _busy ? null : _rescue,
                child: const Text('기록 복구 (자동 백업에서 되살리기)'),
              ),
            ],
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
    final c = context.colors;
    final weekStart = ref.watch(
      appearanceProvider.select((a) => a.weekStart.weekday),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MonthView.horizontalPadding,
        10,
        MonthView.horizontalPadding,
        4,
      ),
      child: Row(
        children: [
          for (final weekday in weekdayOrder(weekStartWeekday: weekStart))
            Expanded(
              child: Center(
                child: Text(
                  _names[weekday]!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: switch (weekday) {
                      DateTime.sunday => c.red,
                      DateTime.saturday => c.blue,
                      _ => c.muted,
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
