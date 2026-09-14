import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_info.dart';
import '../../domain/appearance.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/pro_limits.dart';
import '../../state/appearance_providers.dart';
import '../../state/preset_providers.dart';
import '../../state/pro_providers.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';
import '../app_theme.dart';
import '../backup/backup_page.dart';
import '../backup/trash_page.dart';
import '../common/app_icons.dart';
import '../common/ink_pill.dart';
import '../common/tab_header.dart';
import '../home/ink_nav_bar.dart';
import '../onboarding/onboarding_page.dart';
import '../presets/preset_list_page.dart';
import '../pro/paywall_page.dart';
import '../pro/pro_gate.dart';
import '../settlement/cycle_start_dialog.dart';
import '../sites/site_list_page.dart';
import 'privacy_page.dart';
import 'tax_rates_page.dart';

/// 설정: 화면(큰글씨·화면 모드·주 시작·테마 색), 기록, 정산, 백업, 프로, 앱 정보.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final isPro = ref.watch(proProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final c = context.colors;
    final sites = ref.watch(sitesProvider).valueOrNull ?? const [];
    final presets = ref.watch(presetsProvider).valueOrNull ?? const [];
    final cycleStart = ref.watch(settleCycleStartDayProvider).valueOrNull ?? 1;

    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      bottomNavigationBar: const NavSpacer(),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const TabHeader(title: '설정'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('화면', muted: true),
                  _ChoiceRow<TextSize>(
                    label: '글씨 크기',
                    options: TextSize.values,
                    selected: appearance.textSize,
                    labelOf: (v) => v.label,
                    keyOf: (v) => 'text-size-${v.name}',
                    onSelected: notifier.setTextSize,
                  ),
                  _ChoiceRow<ScreenMode>(
                    label: '화면 모드',
                    options: ScreenMode.values,
                    selected: appearance.screenMode,
                    labelOf: (v) => v.label,
                    keyOf: (v) => 'screen-mode-${v.name}',
                    onSelected: notifier.setScreenMode,
                  ),
                  _ChoiceRow<WeekStart>(
                    label: '주 시작',
                    options: WeekStart.values,
                    selected: appearance.weekStart,
                    labelOf: (v) => v.label,
                    keyOf: (v) => 'week-start-${v.name}',
                    onSelected: notifier.setWeekStart,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text.rich(
                            TextSpan(
                              text: '테마 색',
                              style: _rowLabel(c),
                              children: [
                                if (!isPro)
                                  TextSpan(
                                    text: '  프로',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: c.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in themeColorOptions)
                              _ColorDot(
                                key: ValueKey('theme-color-${option.id}'),
                                option: option,
                                selected:
                                    appearance.themeColorId == option.id,
                                onTap: () async {
                                  if (option.id != 0 && !isPro) {
                                    final ok = await ensurePro(
                                      context,
                                      ref,
                                      feature: ProFeature.theme,
                                    );
                                    if (!ok) return;
                                  }
                                  notifier.setThemeColor(option.id);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SectionLabel('기록', muted: true),
                  _Row(
                    key: const ValueKey('sites'),
                    title: '업체(현장) 관리',
                    subtitle: sites.isEmpty
                        ? '이름 · 단가 · 색 · 세금 방식'
                        : sites.map((s) => s.name).join(' · '),
                    onTap: () => push(const SiteListPage()),
                  ),
                  _Row(
                    key: const ValueKey('presets'),
                    title: '프리셋 관리',
                    subtitle: presets.isEmpty
                        ? '공수 버튼 만들기'
                        : presets
                              .map(
                                (p) => p.centiGongsu == 0
                                    ? p.name
                                    : formatGongsu(p.centiGongsu),
                              )
                              .join(' · '),
                    onTap: () => push(const PresetListPage()),
                  ),
                  _Row(
                    key: const ValueKey('job-presets'),
                    title: '직군 프리셋 다시 고르기',
                    subtitle: '건설 · 조선소 기본 세트. 직접 고친 것은 그대로',
                    onTap: () => push(const OnboardingPage(standalone: true)),
                  ),
                  _Row(
                    key: const ValueKey('trash'),
                    title: '삭제된 기록',
                    subtitle: '지운 공수·부가항목 되살리기',
                    onTap: () => push(const TrashPage()),
                  ),
                  const SectionLabel('정산', muted: true),
                  _Row(
                    key: const ValueKey('tax'),
                    title: '세금 · 요율 설정',
                    subtitle: '${DateTime.now().year}년 요율 · 끝전 처리',
                    onTap: () => push(const TaxRatesPage()),
                  ),
                  _Row(
                    key: const ValueKey('cycle-start'),
                    title: '정산 마감일',
                    subtitle: cycleStartLabel(cycleStart),
                    onTap: () =>
                        showCycleStartDialog(context, ref, current: cycleStart),
                  ),
                  const SectionLabel('백업', muted: true),
                  _Row(
                    key: const ValueKey('backup'),
                    title: '백업 / 복원',
                    subtitle: '텍스트 · 파일 · 자동 스냅샷',
                    onTap: () => push(const BackupPage()),
                  ),
                  const SectionLabel('프로', muted: true),
                  _Row(
                    key: const ValueKey('pro-tile'),
                    title: isPro ? '프로 사용 중' : kProName,
                    subtitle: isPro
                        ? 'PDF 확인서 · 홈 위젯 · 업체 4개+ · 테마'
                        : 'PDF 확인서 · 홈 위젯 · 업체 4개+ · 테마 · $proListPriceLabel 한 번',
                    strong: true,
                    trailing: isPro
                        ? Icon(AppIcons.verified, color: c.gold)
                        : Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.gold,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: const Text(
                              '보기',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    onTap: () => push(const PaywallPage()),
                  ),
                  const SectionLabel('앱 정보', muted: true),
                  _Row(
                    title: '버전',
                    trailing: Text(
                      kAppVersion,
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  ),
                  _Row(
                    key: const ValueKey('privacy'),
                    title: '개인정보처리방침',
                    subtitle: '수집하는 정보 없음 · 서버 없음',
                    onTap: () => push(const PrivacyPage()),
                  ),
                  _Row(
                    title: '오픈소스 라이선스',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: kAppName,
                      applicationVersion: kAppVersion,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _rowLabel(AppColors c) =>
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text);
}

/// 설정 줄 — 위에 옅은 선, 제목 + 작은 설명, 오른쪽 꺾쇠(또는 [trailing]).
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.strong = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: c.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : Icon(AppIcons.chevronRight, size: 18, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// "글씨 크기 | 보통 크게 아주 크게" — 왼쪽 이름, 오른쪽 알약(넘치면 줄바꿈).
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.keyOf,
    required this.onSelected,
  });

  final String label;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final String Function(T) keyOf;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(label, style: SettingsPage._rowLabel(context.colors)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                InkPill(
                  key: ValueKey(keyOf(option)),
                  label: labelOf(option),
                  height: 34,
                  fontSize: 12.5,
                  selected: option == selected,
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ThemeColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = Color(option.argb);
    return Tooltip(
      message: option.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.gold : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(AppIcons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
