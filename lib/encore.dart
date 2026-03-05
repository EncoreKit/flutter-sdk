/// Flutter plugin wrapping the native Encore iOS and Android SDKs.
///
/// Provides monetization, offers, and entitlements through platform channels
/// backed by the Encore XCFramework (iOS) and AAR (Android) binaries.
///
/// ```dart
/// import 'package:encore/encore.dart';
///
/// await Encore.shared.configure(apiKey: 'your_key');
/// await Encore.shared.identify(userId: 'user_123');
/// final result = await Encore.shared.placement('cancel_flow').show();
/// ```
library encore;

export 'src/encore.dart' show Encore, PlacementBuilder;
export 'src/models/billing_purchase_result.dart';
export 'src/models/log_level.dart';
export 'src/models/presentation_result.dart';
export 'src/models/purchase_request.dart';
export 'src/models/user_attributes.dart';
