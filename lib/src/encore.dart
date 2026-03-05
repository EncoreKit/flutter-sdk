import 'encore_platform_channel.dart';
import 'models/billing_purchase_result.dart';
import 'models/log_level.dart';
import 'models/presentation_result.dart';
import 'models/user_attributes.dart';

/// Main entry point for the Encore Flutter SDK.
///
/// Access via [Encore.shared]. Configure early in app lifecycle,
/// identify users after auth, then present offers via [placement].
///
/// ```dart
/// // In main() or early init
/// await Encore.shared.configure(apiKey: 'key_xxx', logLevel: LogLevel.debug);
///
/// // After auth
/// await Encore.shared.identify(userId: 'user_123');
///
/// // At retention moment
/// final result = await Encore.shared.placement('cancel_flow').show();
/// ```
class Encore {
  static final Encore shared = Encore._();

  final EncorePlatformChannel _channel = EncorePlatformChannel();

  Encore._();

  /// Configures the SDK with your API key. Call once, early in app lifecycle.
  Future<void> configure({
    required String apiKey,
    LogLevel logLevel = LogLevel.none,
  }) {
    return _channel.configure(
      apiKey: apiKey,
      logLevel: logLevel.nativeValue,
    );
  }

  /// Associates a user ID with SDK events and entitlements.
  Future<void> identify({
    required String userId,
    UserAttributes? attributes,
  }) {
    return _channel.identify(
      userId: userId,
      attributes: attributes?.toMap(),
    );
  }

  /// Merges new attributes into the current user's profile.
  Future<void> setUserAttributes(UserAttributes attributes) {
    return _channel.setUserAttributes(attributes.toMap());
  }

  /// Clears user data and generates a new anonymous ID. Call on logout.
  Future<void> reset() {
    return _channel.reset();
  }

  /// Creates a placement builder for presenting offers.
  ///
  /// ```dart
  /// final result = await Encore.shared.placement('cancel_flow').show();
  /// ```
  PlacementBuilder placement([String? id]) {
    return PlacementBuilder._(id, _channel);
  }

  /// Registers a handler invoked when Encore's offer flow completes and a
  /// purchase is needed. The handler receives `productId` and `placementId`
  /// and should trigger purchase via your subscription manager.
  ///
  /// The native SDK **waits** for this handler to complete before continuing
  /// its flow (e.g., reconciling transactions, granting entitlements).
  ///
  /// ```dart
  /// Encore.shared.onPurchaseRequest((productId, placementId) async {
  ///   await purchases.purchase(productId);
  /// });
  /// ```
  void onPurchaseRequest(
    Future<void> Function(String productId, String placementId) handler,
  ) {
    _channel.setOnPurchaseRequest(handler);
  }

  /// Registers a callback invoked after Encore completes a native billing
  /// purchase (StoreKit on iOS, Play Billing on Android). Only fires when no
  /// [onPurchaseRequest] handler is set.
  ///
  /// ```dart
  /// Encore.shared.onPurchaseComplete((result, productId) {
  ///   print('Purchased $productId: token=${result.purchaseToken}');
  /// });
  /// ```
  void onPurchaseComplete(
    void Function(BillingPurchaseResult result, String productId) handler,
  ) {
    _channel.setOnPurchaseComplete((resultMap, productId) {
      handler(BillingPurchaseResult.fromMap(resultMap), productId);
    });
  }

  /// Registers a handler invoked for all not-granted outcomes (dismiss, no
  /// offers, experiment control). Signals "Encore didn't result in a purchase
  /// -- run your original button logic."
  ///
  /// ```dart
  /// Encore.shared.onPassthrough((placementId) {
  ///   router.handleOriginalAction(placementId);
  /// });
  /// ```
  void onPassthrough(void Function(String placementId) handler) {
    _channel.setOnPassthrough(handler);
  }
}

/// Fluent builder for presenting Encore offers.
///
/// Create via [Encore.placement] and call [show] to present.
///
/// ```dart
/// final result = await Encore.shared.placement('cancel_flow').show();
/// ```
class PlacementBuilder {
  final String? _id;
  final EncorePlatformChannel _channel;

  PlacementBuilder._(this._id, this._channel);

  /// Fetches offers and presents the native offer sheet.
  ///
  /// Returns a [PresentationResult] indicating whether an offer was granted
  /// or not. The native SDK handles all UI presentation.
  Future<PresentationResult> show() {
    return _channel.showPlacement(placementId: _id);
  }
}
