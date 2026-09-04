import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/purchase_service.dart';
import '../../state/pro_providers.dart';
import '../../state/purchase_providers.dart';

/// 앱이 살아 있는 동안 스토어 결제 결과를 항상 듣는다.
///
/// 페이월 화면이 닫힌 뒤 승인된 결제(가족 공유 승인, 앱 종료 후 완료)도 여기서
/// 잠금 해제된다. 잠금 해제 저장은 스토어 "완료 처리" 전에 일어난다
/// (PurchaseService.entitlementHandler).
class PurchaseSyncer extends ConsumerStatefulWidget {
  const PurchaseSyncer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PurchaseSyncer> createState() => _PurchaseSyncerState();
}

class _PurchaseSyncerState extends ConsumerState<PurchaseSyncer> {
  StreamSubscription<PurchaseOutcome>? _sub;

  @override
  void initState() {
    super.initState();
    final service = ref.read(purchaseServiceProvider);
    service.entitlementHandler = () => ref.read(proProvider.notifier).unlock();
    _sub = service.outcomes.listen((outcome) {
      if (outcome == PurchaseOutcome.purchased ||
          outcome == PurchaseOutcome.restored) {
        ref.read(proProvider.notifier).unlock();
      }
    });
    if (!ref.read(proProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.reconcileAtStartup();
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
