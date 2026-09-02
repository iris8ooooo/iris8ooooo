import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/pro_limits.dart';

/// 구매 흐름의 결과 이벤트 (스토어 → 앱).
enum PurchaseOutcome {
  /// 결제 완료 → 프로 잠금 해제
  purchased,

  /// 이전 구매 복원됨 → 프로 잠금 해제
  restored,

  /// 승인 대기(가족 공유 승인 등)
  pending,

  /// 사용자가 취소
  canceled,

  /// 스토어 오류
  error,
}

/// 스토어 결제 추상화. 위젯 코드는 in_app_purchase 를 직접 부르지 않는다
/// (M4 규칙과 같은 이유 — 테스트는 가짜 주입).
abstract class PurchaseService {
  /// 스토어 연결 가능 여부 (시뮬레이터·스토어 미로그인이면 false).
  Future<bool> isAvailable();

  /// 스토어에 등록된 가격 표시 문자열 (예: "₩6,600"). 못 받으면 null.
  Future<String?> fetchPrice();

  Stream<PurchaseOutcome> get outcomes;

  /// 프로 구매 시작 (비소모성).
  Future<void> buy();

  /// 이전 구매 복원 (기기 변경·재설치).
  Future<void> restore();

  void dispose();
}

/// in_app_purchase 구현. 상품 ID 는 [proProductId] 하나.
///
/// 검증은 스토어 응답(purchased/restored)만 믿는다 — 서버 없음 원칙.
/// 구매 상태는 기기에만 저장하므로 다른 기기에서는 '이전 구매 복원'을 쓴다.
class InAppPurchaseService implements PurchaseService {
  InAppPurchaseService() {
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchases,
      onError: (_) => _controller.add(PurchaseOutcome.error),
    );
  }

  final _controller = StreamController<PurchaseOutcome>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  @override
  Stream<PurchaseOutcome> get outcomes => _controller.stream;

  @override
  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  Future<ProductDetails?> _loadProduct() async {
    if (_product != null) return _product;
    final response = await InAppPurchase.instance.queryProductDetails({
      proProductId,
    });
    if (response.productDetails.isEmpty) return null;
    return _product = response.productDetails.first;
  }

  @override
  Future<String?> fetchPrice() async {
    try {
      return (await _loadProduct())?.price;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> buy() async {
    final product = await _loadProduct();
    if (product == null) {
      _controller.add(PurchaseOutcome.error);
      return;
    }
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      _controller.add(PurchaseOutcome.error);
    }
  }

  @override
  Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      _controller.add(PurchaseOutcome.error);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != proProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
          _controller.add(PurchaseOutcome.purchased);
        case PurchaseStatus.restored:
          _controller.add(PurchaseOutcome.restored);
        case PurchaseStatus.pending:
          _controller.add(PurchaseOutcome.pending);
        case PurchaseStatus.canceled:
          _controller.add(PurchaseOutcome.canceled);
        case PurchaseStatus.error:
          _controller.add(PurchaseOutcome.error);
      }
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
