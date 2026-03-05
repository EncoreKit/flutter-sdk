import 'package:flutter_test/flutter_test.dart';
import 'package:encore_flutter_sdk/encore_flutter_sdk.dart';

void main() {
  group('PresentationResult', () {
    test('parses granted from map', () {
      final result = PresentationResult.fromMap({
        'type': 'granted',
        'offerId': 'offer_1',
        'campaignId': 'campaign_1',
      });

      expect(result, isA<PresentationResultGranted>());
      final granted = result as PresentationResultGranted;
      expect(granted.offerId, 'offer_1');
      expect(granted.campaignId, 'campaign_1');
    });

    test('parses notGranted from map', () {
      final result = PresentationResult.fromMap({
        'type': 'notGranted',
        'reason': 'user_tapped_close',
      });

      expect(result, isA<PresentationResultNotGranted>());
      final notGranted = result as PresentationResultNotGranted;
      expect(notGranted.reason, 'user_tapped_close');
    });

    test('defaults to notGranted for unknown type', () {
      final result = PresentationResult.fromMap({'type': 'unknown'});
      expect(result, isA<PresentationResultNotGranted>());
    });
  });

  group('UserAttributes', () {
    test('toMap omits null fields', () {
      const attrs = UserAttributes(email: 'test@test.com');
      final map = attrs.toMap();

      expect(map['email'], 'test@test.com');
      expect(map.containsKey('firstName'), false);
      expect(map.containsKey('custom'), false);
    });

    test('toMap includes custom when non-empty', () {
      const attrs = UserAttributes(custom: {'key': 'value'});
      final map = attrs.toMap();

      expect(map['custom'], {'key': 'value'});
    });
  });

  group('BillingPurchaseResult', () {
    test('fromMap parses all fields', () {
      final result = BillingPurchaseResult.fromMap({
        'productId': 'prod_1',
        'purchaseToken': 'token_abc',
        'orderId': 'order_123',
        'transactionId': 'txn_456',
      });

      expect(result.productId, 'prod_1');
      expect(result.purchaseToken, 'token_abc');
      expect(result.orderId, 'order_123');
      expect(result.transactionId, 'txn_456');
    });
  });

  group('LogLevel', () {
    test('nativeValue returns uppercase', () {
      expect(LogLevel.debug.nativeValue, 'DEBUG');
      expect(LogLevel.none.nativeValue, 'NONE');
    });
  });
}
