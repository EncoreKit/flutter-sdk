/// Result of a successful native billing purchase (Play Billing on Android,
/// StoreKit on iOS).
///
/// Delivered via [Encore.onPurchaseComplete] when the native SDK handles
/// a purchase without an external subscription manager.
class BillingPurchaseResult {
  final String productId;
  final String? purchaseToken;
  final String? orderId;
  final String? transactionId;

  const BillingPurchaseResult({
    required this.productId,
    this.purchaseToken,
    this.orderId,
    this.transactionId,
  });

  factory BillingPurchaseResult.fromMap(Map<String, dynamic> map) {
    return BillingPurchaseResult(
      productId: map['productId'] as String,
      purchaseToken: map['purchaseToken'] as String?,
      orderId: map['orderId'] as String?,
      transactionId: map['transactionId'] as String?,
    );
  }

  @override
  String toString() =>
      'BillingPurchaseResult(productId: $productId, purchaseToken: $purchaseToken, '
      'orderId: $orderId, transactionId: $transactionId)';
}
