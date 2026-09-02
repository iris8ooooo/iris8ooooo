import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_info.dart';
import '../../domain/appearance.dart';
import '../../domain/pro_limits.dart';
import '../../state/appearance_providers.dart';
import '../../state/pro_providers.dart';
import '../onboarding/onboarding_page.dart';
import '../presets/preset_list_page.dart';
import '../pro/paywall_page.dart';
import '../pro/pro_gate.dart';
import 'privacy_page.dart';
import 'tax_rates_page.dart';

/// 설정: 화면(큰글씨·화면 모드·주 시작 요일·테마 색), 프로, 프리셋, 정산, 앱 정보.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final isPro = ref.watch(proProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle('화면'),
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
            label: '주 시작 요일',
            options: WeekStart.values,
            selected: appearance.weekStart,
            labelOf: (v) => v.label,
            keyOf: (v) => 'week-start-${v.name}',
            onSelected: notifier.setWeekStart,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                const Text('테마 색', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                if (!isPro)
                  Text(
                    '프로',
                    style: TextStyle(fontSize: 13, color: scheme.primary),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            children: [
              for (final option in themeColorOptions)
                _ColorDot(
                  key: ValueKey('theme-color-${option.id}'),
                  option: option,
                  selected: appearance.themeColorId == option.id,
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
          const SizedBox(height: 16),
          _SectionTitle('프로'),
          ListTile(
            key: const ValueKey('pro-tile'),
            leading: Icon(
              isPro ? Icons.verified : Icons.workspace_premium,
              color: scheme.primary,
            ),
            title: Text(isPro ? '프로 사용 중' : '공수장부 프로 · 한 번만 결제'),
            subtitle: Text(
              isPro
                  ? 'PDF 확인서 · 홈 위젯 · 업체 4개+ · 테마 색'
                  : 'PDF 확인서 · 홈 위젯 · 업체 4개+ · 테마 색 (구독 아님)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PaywallPage())),
          ),
          _SectionTitle('공수 버튼(프리셋)'),
          ListTile(
            key: const ValueKey('job-presets'),
            leading: const Icon(Icons.engineering),
            title: const Text('직군 프리셋 다시 고르기'),
            subtitle: const Text('건설 · 조선소 기본 세트. 직접 고친 것은 그대로'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingPage(standalone: true),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('프리셋 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PresetListPage())),
          ),
          _SectionTitle('정산'),
          ListTile(
            leading: const Icon(Icons.percent),
            title: const Text('세금 · 요율 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TaxRatesPage())),
          ),
          _SectionTitle('앱 정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('버전'),
            trailing: Text(kAppVersion, style: const TextStyle(fontSize: 16)),
          ),
          ListTile(
            key: const ValueKey('privacy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            subtitle: const Text('수집하는 정보 없음 · 서버 없음'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PrivacyPage())),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('오픈소스 라이선스'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: '공수장부',
              applicationVersion: kAppVersion,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final option in options)
              ChoiceChip(
                key: ValueKey(keyOf(option)),
                label: Text(labelOf(option)),
                selected: option == selected,
                onSelected: (_) => onSelected(option),
              ),
          ],
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
    final color = Color(option.argb);
    return Tooltip(
      message: option.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }
}
