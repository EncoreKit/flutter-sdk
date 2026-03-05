import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encore/encore.dart';
import 'package:encore/src/encore_platform_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.encorekit/encore');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      switch (call.method) {
        case 'configure':
        case 'identify':
        case 'setUserAttributes':
        case 'reset':
        case 'registerOnPurchaseRequest':
        case 'registerOnPurchaseComplete':
        case 'registerOnPassthrough':
          return null;
        case 'showPlacement':
          return {'type': 'granted', 'offerId': 'test_offer'};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('EncorePlatformChannel outbound calls', () {
    late EncorePlatformChannel platformChannel;

    setUp(() {
      platformChannel = EncorePlatformChannel();
    });

    test('configure sends correct arguments', () async {
      await platformChannel.configure(apiKey: 'pk_test', logLevel: 'DEBUG');

      expect(log.length, 1);
      expect(log.first.method, 'configure');
      expect(log.first.arguments['apiKey'], 'pk_test');
      expect(log.first.arguments['logLevel'], 'DEBUG');
    });

    test('identify sends userId and attributes', () async {
      await platformChannel.identify(
        userId: 'user_1',
        attributes: {'email': 'a@b.com'},
      );

      expect(log.length, 1);
      expect(log.first.method, 'identify');
      expect(log.first.arguments['userId'], 'user_1');
      expect(log.first.arguments['attributes'], {'email': 'a@b.com'});
    });

    test('identify omits attributes when null', () async {
      await platformChannel.identify(userId: 'user_1');

      expect(log.first.arguments.containsKey('attributes'), false);
    });

    test('setUserAttributes sends attributes map', () async {
      await platformChannel.setUserAttributes({'tier': 'premium'});

      expect(log.first.method, 'setUserAttributes');
      expect(log.first.arguments['attributes'], {'tier': 'premium'});
    });

    test('reset sends method call', () async {
      await platformChannel.reset();

      expect(log.first.method, 'reset');
    });

    test('showPlacement returns PresentationResult', () async {
      final result = await platformChannel.showPlacement(placementId: 'test');

      expect(log.first.method, 'showPlacement');
      expect(log.first.arguments['placementId'], 'test');
      expect(result, isA<PresentationResultGranted>());
      expect((result as PresentationResultGranted).offerId, 'test_offer');
    });

    test('showPlacement sends null placementId when not provided', () async {
      await platformChannel.showPlacement();

      expect(log.first.arguments['placementId'], isNull);
    });
  });

  group('EncorePlatformChannel handler registration', () {
    late EncorePlatformChannel platformChannel;

    setUp(() {
      platformChannel = EncorePlatformChannel();
    });

    test('setOnPurchaseRequest sends registration call', () async {
      platformChannel.setOnPurchaseRequest((req) async {});

      await Future.delayed(Duration.zero);
      expect(log.any((c) => c.method == 'registerOnPurchaseRequest'), true);
    });

    test('setOnPurchaseRequest with null does not send registration', () async {
      platformChannel.setOnPurchaseRequest(null);

      await Future.delayed(Duration.zero);
      expect(log.any((c) => c.method == 'registerOnPurchaseRequest'), false);
    });

    test('setOnPurchaseComplete sends registration call', () async {
      platformChannel.setOnPurchaseComplete((result, productId) {});

      await Future.delayed(Duration.zero);
      expect(log.any((c) => c.method == 'registerOnPurchaseComplete'), true);
    });

    test('setOnPassthrough sends registration call', () async {
      platformChannel.setOnPassthrough((placementId) {});

      await Future.delayed(Duration.zero);
      expect(log.any((c) => c.method == 'registerOnPassthrough'), true);
    });
  });

  group('Encore public API', () {
    test('configure delegates to platform channel', () async {
      await Encore.shared.configure(apiKey: 'pk_test', logLevel: LogLevel.debug);

      expect(log.any((c) => c.method == 'configure'), true);
      final call = log.firstWhere((c) => c.method == 'configure');
      expect(call.arguments['apiKey'], 'pk_test');
      expect(call.arguments['logLevel'], 'DEBUG');
    });

    test('identify delegates with attributes', () async {
      await Encore.shared.identify(
        userId: 'user_1',
        attributes: const UserAttributes(email: 'test@test.com'),
      );

      final call = log.firstWhere((c) => c.method == 'identify');
      expect(call.arguments['userId'], 'user_1');
      expect(call.arguments['attributes']['email'], 'test@test.com');
    });

    test('reset delegates to platform channel', () async {
      await Encore.shared.reset();

      expect(log.any((c) => c.method == 'reset'), true);
    });

    test('placement().show() returns PresentationResult', () async {
      final result = await Encore.shared.placement('test_pl').show();

      final call = log.firstWhere((c) => c.method == 'showPlacement');
      expect(call.arguments['placementId'], 'test_pl');
      expect(result, isA<PresentationResultGranted>());
    });

    test('placement with null id sends null', () async {
      await Encore.shared.placement().show();

      final call = log.firstWhere((c) => c.method == 'showPlacement');
      expect(call.arguments['placementId'], isNull);
    });
  });
}
