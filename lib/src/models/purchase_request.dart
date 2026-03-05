/// Data passed to the [Encore.onPurchaseRequest] handler when a user accepts
/// an offer and a purchase is needed.
class PurchaseRequest {
  /// The store product identifier to purchase (e.g. `com.yourapp.annual.trial`).
  final String productId;

  /// The placement that triggered this purchase request.
  final String placementId;

  /// App Store Connect promotional offer identifier, if a promotional offer
  /// should be applied to this purchase. `null` for standard purchases.
  final String? promoOfferId;

  const PurchaseRequest({
    required this.productId,
    required this.placementId,
    this.promoOfferId,
  });

  factory PurchaseRequest.fromMap(Map<String, dynamic> map) {
    final promoId = map['promoOfferId'] as String?;
    return PurchaseRequest(
      productId: map['productId'] as String,
      placementId: map['placementId'] as String,
      promoOfferId: (promoId != null && promoId.isNotEmpty) ? promoId : null,
    );
  }

  @override
  String toString() =>
      'PurchaseRequest(productId: $productId, placementId: $placementId, promoOfferId: $promoOfferId)';
}
