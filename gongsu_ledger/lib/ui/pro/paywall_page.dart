import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pro_limits.dart';
import '../../services/purchase_service.dart';
import '../../state/pro_providers.dart';
import '../../state/purchase_providers.dart';

/// 프로 안내·구매·복원 화면. 구독이 아닌 일회성 결제임을 분명히 한다.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key, this.feature});

  /// 어떤 기능을 쓰려다 왔는지 (안내문에 표시). null 이면 설정에서 진입.
  final ProFeature? feature;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  StreamSubscription<PurchaseOutcome>? _sub;
  String? _price;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final service = ref.read(purchaseServiceProvider);
    _sub = service.outcomes.listen(_onOutcome);
    service.fetchPrice().then((p) {
      if (mounted) setState(() => _price = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onOutcome(PurchaseOutcome outcome) async {
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        await ref.read(proProvider.notifier).unlock();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = null;
        });
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('프로가 켜졌어요'),
            content: Text(
              outcome == PurchaseOutcome.restored
                  ? '이전 구매를 복원했어요. 모든 프로 기능을 쓸 수 있어요.'
                  : '고마워요! 모든 프로 기능을 쓸 수 있어요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      case PurchaseOutcome.pending:
        setState(() {
          _busy = false;
          _message = '승인을 기다리고 있어요. 승인되면 자동으로 켜져요.';
        });
      case PurchaseOutcome.canceled:
        setState(() {
          _busy = false;
          _message = null;
        });
      case PurchaseOutcome.error:
        setState(() {
          _busy = false;
          _message = '스토어와 연결하지 못했어요. 잠시 뒤 다시 시도해 주세요.';
        });
    }
  }

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final service = ref.read(purchaseServiceProvider);
    if (!await service.isAvailable()) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '지금은 스토어를 사용할 수 없어요. 스토어 로그인 상태를 확인해 주세요.';
      });
      return;
    }
    await service.buy();
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _message = '이전 구매를 찾는 중…';
    });
    await ref.read(purchaseServiceProvider).restore();
    // 복원할 것이 없으면 스토어가 아무 신호도 주지 않는다 — 잠시 뒤 안내.
    await Future<void>.delayed(const Duration(seconds: 6));
    if (!mounted || !_busy) return;
    setState(() {
      _busy = false;
      _message = ref.read(proProvider)
          ? null
          : '복원할 구매를 찾지 못했어요. 구매했던 스토어 계정으로 로그인되어 있는지 확인해 주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proProvider);
    final scheme = Theme.of(context).colorScheme;
    final priceLabel = _price ?? proListPriceLabel;

    return Scaffold(
      appBar: AppBar(title: const Text('공수장부 프로')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.feature != null && !isPro)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "'${widget.feature!.label}'은 프로 기능이에요.",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          Text(
            isPro ? '프로를 사용 중이에요' : '한 번만 결제 · 구독 아님',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            isPro
                ? '모든 프로 기능이 켜져 있어요. 기기를 바꾸면 같은 스토어 계정으로 로그인한 뒤 "이전 구매 복원"을 누르세요.'
                : '한 번 사면 계속 쓰는 프로 기능이에요. 광고는 프로든 무료든 영원히 없어요.',
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final f in ProFeature.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.check_circle,
                color: isPro ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(f.label),
              subtitle: Text(switch (f) {
                ProFeature.pdf => '노동청·업체에 낼 수 있는 월 공수 확인서',
                ProFeature.widget => '홈 화면에서 이번 달 공수·실수령 바로 확인',
                ProFeature.sites => '무료는 업체 $freeSiteLimit개까지',
                ProFeature.theme => '앱 색상 바꾸기',
              }),
            ),
          const SizedBox(height: 20),
          if (!isPro) ...[
            FilledButton(
              key: const ValueKey('buy-pro'),
              onPressed: _busy ? null : _buy,
              child: Text('프로 구매하기 · $priceLabel'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('restore-pro'),
              onPressed: _busy ? null : _restore,
              child: const Text('이전 구매 복원'),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _message!,
                key: const ValueKey('paywall-message'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            '결제는 App Store / Google Play 가 처리하고, 앱은 결제 정보를 저장하지 않아요. '
            '가격은 스토어 설정에 따라 표시돼요.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
