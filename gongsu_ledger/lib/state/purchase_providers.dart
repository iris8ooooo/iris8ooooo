import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';

/// 스토어 결제 서비스. 테스트에서는 가짜로 override.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = InAppPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});
