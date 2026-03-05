/// Data passed to the [Encore.onPurchaseRequest] handler when a user accepts
/// an offer and a purchase is needed.
class PurchaseRequest {
  /// The store product identifier to purchase (e.g. `com.yourapp.annual.trial`).
  final String productId;

  /// The placement that triggered this purchase request.
  final String placementId;

  const PurchaseRequest({
    required this.productId,
    required this.placementId,
  });

  factory PurchaseRequest.fromMap(Map<String, dynamic> map) {
    return PurchaseRequest(
      productId: map['productId'] as String,
      placementId: map['placementId'] as String,
    );
  }

  @override
  String toString() =>
      'PurchaseRequest(productId: $productId, placementId: $placementId)';
}
