import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/seed/default_presets.dart';
import '../../state/db_providers.dart';
import '../../state/prefs_providers.dart';
import '../../state/pro_providers.dart';

/// 첫 실행 온보딩: 직군 선택 → 기본 프리셋 세트. 로그인·회원가입 없음.
///
/// 규칙(CLAUDE.md 선확정): 사용자가 수정하지 않은 시드 프리셋만 교체하고,
/// 손댄 프리셋·직접 만든 프리셋은 절대 건드리지 않는다.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.standalone = false});

  /// 설정에서 다시 고를 때 true — 앱바·뒤로가기, 완료 시 pop.
  final bool standalone;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _busy = false;

  Future<void> _choose(JobKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(presetRepoProvider).applyJobSeed(kind);
      await ref
          .read(localPrefsProvider)
          .setString(SettingsRepository.keyJobKind, kind.name);
      try {
        await ref
            .read(settingsRepoProvider)
            .set(SettingsRepository.keyJobKind, kind.name);
      } catch (_) {}
      await ref.read(onboardingDoneProvider.notifier).markDone();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장하지 못했어요'),
          content: const Text('기록 저장소를 열지 못했어요. 앱을 완전히 종료한 뒤 다시 열어 보세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (widget.standalone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == JobKind.custom
                ? '기본 프리셋을 정리했어요'
                : '${kind.label} 프리셋으로 바꿨어요',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: widget.standalone
          ? AppBar(title: const Text('직군 프리셋 다시 고르기'))
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            if (!widget.standalone) ...[
              Text(
                '공수장부',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const _Bullet('광고 없음'),
              const _Bullet('인터넷 없어도 전부 동작'),
              const _Bullet('기록은 내 폰 안에만 · 회원가입 없음'),
              const SizedBox(height: 28),
            ],
            const Text(
              '어떤 일을 하세요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '자주 쓰는 공수 버튼을 미리 만들어 드려요.',
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final kind in JobKind.values)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  key: ValueKey('onboard-${kind.name}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _busy ? null : () => _choose(kind),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kind.label,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kind.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '나중에 설정에서 바꿀 수 있어요. 직접 만들거나 고친 프리셋은 그대로 남아요.',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          Icons.check,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
      ],
    ),
  );
}
