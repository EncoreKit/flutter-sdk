import 'package:flutter_test/flutter_test.dart';
import 'package:encore_flutter_sdk/encore_flutter_sdk.dart';

void main() {
  group('PresentationResult', () {
    test('parses granted with all fields', () {
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

    test('parses granted with null optional fields', () {
      final result = PresentationResult.fromMap({'type': 'granted'});

      expect(result, isA<PresentationResultGranted>());
      final granted = result as PresentationResultGranted;
      expect(granted.offerId, isNull);
      expect(granted.campaignId, isNull);
    });

    test('parses notGranted with reason', () {
      final result = PresentationResult.fromMap({
        'type': 'notGranted',
        'reason': 'user_tapped_close',
      });

      expect(result, isA<PresentationResultNotGranted>());
      expect((result as PresentationResultNotGranted).reason, 'user_tapped_close');
    });

    test('notGranted defaults to unknown when reason missing', () {
      final result = PresentationResult.fromMap({'type': 'notGranted'});

      expect(result, isA<PresentationResultNotGranted>());
      expect((result as PresentationResultNotGranted).reason, 'unknown');
    });

    test('unknown type defaults to notGranted', () {
      final result = PresentationResult.fromMap({'type': 'something_new'});
      expect(result, isA<PresentationResultNotGranted>());
    });

    test('toString includes fields', () {
      const granted = PresentationResultGranted(offerId: 'o1', campaignId: 'c1');
      expect(granted.toString(), contains('o1'));
      expect(granted.toString(), contains('c1'));

      const notGranted = PresentationResultNotGranted(reason: 'dismissed');
      expect(notGranted.toString(), contains('dismissed'));
    });
  });

  group('UserAttributes', () {
    test('toMap omits all null fields', () {
      const attrs = UserAttributes();
      final map = attrs.toMap();

      expect(map, isEmpty);
    });

    test('toMap includes only non-null fields', () {
      const attrs = UserAttributes(
        email: 'test@test.com',
        subscriptionTier: 'premium',
      );
      final map = attrs.toMap();

      expect(map['email'], 'test@test.com');
      expect(map['subscriptionTier'], 'premium');
      expect(map.containsKey('firstName'), false);
      expect(map.containsKey('lastName'), false);
      expect(map.containsKey('custom'), false);
    });

    test('toMap includes custom when non-empty', () {
      const attrs = UserAttributes(custom: {'key': 'value', 'k2': 'v2'});
      final map = attrs.toMap();

      expect(map['custom'], {'key': 'value', 'k2': 'v2'});
    });

    test('toMap serializes all fields when set', () {
      const attrs = UserAttributes(
        email: 'e',
        firstName: 'f',
        lastName: 'l',
        phoneNumber: 'p',
        postalCode: 'pc',
        city: 'c',
        state: 's',
        countryCode: 'cc',
        latitude: 'lat',
        longitude: 'lng',
        dateOfBirth: 'dob',
        gender: 'g',
        language: 'lang',
        subscriptionTier: 'st',
        monthsSubscribed: 'ms',
        billingCycle: 'bc',
        lastPaymentAmount: 'lpa',
        lastActiveDate: 'lad',
        totalSessions: 'ts',
        custom: {'a': 'b'},
      );
      final map = attrs.toMap();

      expect(map.length, 20);
      expect(map['email'], 'e');
      expect(map['latitude'], 'lat');
      expect(map['custom'], {'a': 'b'});
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

    test('fromMap handles missing optional fields', () {
      final result = BillingPurchaseResult.fromMap({
        'productId': 'prod_1',
      });

      expect(result.productId, 'prod_1');
      expect(result.purchaseToken, isNull);
      expect(result.orderId, isNull);
      expect(result.transactionId, isNull);
    });

    test('toString includes productId', () {
      final result = BillingPurchaseResult.fromMap({'productId': 'p1'});
      expect(result.toString(), contains('p1'));
    });
  });

  group('PurchaseRequest', () {
    test('fromMap parses fields', () {
      final req = PurchaseRequest.fromMap({
        'productId': 'com.app.annual',
        'placementId': 'cancel_flow',
      });

      expect(req.productId, 'com.app.annual');
      expect(req.placementId, 'cancel_flow');
    });

    test('toString includes fields', () {
      const req = PurchaseRequest(productId: 'p1', placementId: 'pl1');
      expect(req.toString(), contains('p1'));
      expect(req.toString(), contains('pl1'));
    });
  });

  group('LogLevel', () {
    test('nativeValue returns uppercase for all values', () {
      expect(LogLevel.none.nativeValue, 'NONE');
      expect(LogLevel.error.nativeValue, 'ERROR');
      expect(LogLevel.warn.nativeValue, 'WARN');
      expect(LogLevel.info.nativeValue, 'INFO');
      expect(LogLevel.debug.nativeValue, 'DEBUG');
    });

    test('enum has correct number of values', () {
      expect(LogLevel.values.length, 5);
    });
  });
}
