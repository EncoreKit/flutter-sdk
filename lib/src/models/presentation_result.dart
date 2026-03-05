/// Outcome of presenting an offer to the user.
///
/// Maps to `PresentationResult` on both iOS and Android native SDKs.
///
/// ```dart
/// final result = await Encore.shared.placement('cancel_flow').show();
/// switch (result) {
///   case PresentationResultGranted():
///     print('Offer granted');
///   case PresentationResultNotGranted(:final reason):
///     print('Not granted: $reason');
/// }
/// ```
sealed class PresentationResult {
  const PresentationResult();

  factory PresentationResult.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'granted':
        return PresentationResultGranted(
          offerId: map['offerId'] as String?,
          campaignId: map['campaignId'] as String?,
        );
      case 'notGranted':
        return PresentationResultNotGranted(
          reason: map['reason'] as String? ?? 'unknown',
        );
      default:
        return const PresentationResultNotGranted(reason: 'unknown');
    }
  }
}

/// The user completed an offer flow (claimed an offer, earned an entitlement).
class PresentationResultGranted extends PresentationResult {
  final String? offerId;
  final String? campaignId;

  const PresentationResultGranted({this.offerId, this.campaignId});

  @override
  String toString() =>
      'PresentationResultGranted(offerId: $offerId, campaignId: $campaignId)';
}

/// The user did not earn an entitlement (dismissed, no offers, experiment control, etc.).
class PresentationResultNotGranted extends PresentationResult {
  /// Raw reason string from the native SDK.
  ///
  /// Common values: `user_tapped_close`, `user_swiped_down`, `no_offer_available`,
  /// `user_cancelled`, `dismissed`, `error`, `experiment_control`.
  final String reason;

  const PresentationResultNotGranted({required this.reason});

  @override
  String toString() => 'PresentationResultNotGranted(reason: $reason)';
}
