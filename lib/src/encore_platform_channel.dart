import 'dart:async';
import 'package:flutter/services.dart';
import 'models/presentation_result.dart';
import 'models/purchase_request.dart';

/// Low-level platform channel bridge to the native Encore SDKs.
///
/// [MethodChannel] handles request-response calls (configure, identify, show).
/// Native-to-Dart callbacks (onPurchaseRequest, onPurchaseComplete, onPassthrough)
/// are delivered via reverse method calls on the same channel.
///
/// Native handlers are only registered when Dart sets a callback, so the native
/// SDK's fallback behavior (e.g. native StoreKit purchases) is preserved when
/// no Dart handler is set.
class EncorePlatformChannel {
  static const _channel = MethodChannel('com.encorekit/encore');

  Future<void> Function(PurchaseRequest request)? _purchaseRequestHandler;
  Function(Map<String, dynamic> result, String productId)?
      _purchaseCompleteHandler;
  Function(String placementId)? _passthroughHandler;

  EncorePlatformChannel() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  // -- Outbound calls (Dart -> Native) --

  Future<void> configure({
    required String apiKey,
    required String logLevel,
  }) {
    return _channel.invokeMethod('configure', {
      'apiKey': apiKey,
      'logLevel': logLevel,
    });
  }

  Future<void> identify({
    required String userId,
    Map<String, dynamic>? attributes,
  }) {
    return _channel.invokeMethod('identify', {
      'userId': userId,
      if (attributes != null) 'attributes': attributes,
    });
  }

  Future<void> setUserAttributes(Map<String, dynamic> attributes) {
    return _channel.invokeMethod('setUserAttributes', {
      'attributes': attributes,
    });
  }

  Future<void> reset() {
    return _channel.invokeMethod('reset');
  }

  Future<PresentationResult> showPlacement({String? placementId}) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'showPlacement',
      {'placementId': placementId},
    );
    return PresentationResult.fromMap(result ?? {'type': 'notGranted', 'reason': 'error'});
  }

  // -- Handler registration (Dart -> Native, on demand) --

  void setOnPurchaseRequest(
    Future<void> Function(PurchaseRequest request)? handler,
  ) {
    _purchaseRequestHandler = handler;
    if (handler != null) {
      _channel.invokeMethod('registerOnPurchaseRequest');
    }
  }

  void setOnPurchaseComplete(
    Function(Map<String, dynamic> result, String productId)? handler,
  ) {
    _purchaseCompleteHandler = handler;
    if (handler != null) {
      _channel.invokeMethod('registerOnPurchaseComplete');
    }
  }

  void setOnPassthrough(Function(String placementId)? handler) {
    _passthroughHandler = handler;
    if (handler != null) {
      _channel.invokeMethod('registerOnPassthrough');
    }
  }

  // -- Inbound calls (Native -> Dart) --

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPurchaseRequest':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final request = PurchaseRequest.fromMap(args);
        await _purchaseRequestHandler?.call(request);
        return null;

      case 'onPurchaseComplete':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final result = Map<String, dynamic>.from(args['result'] as Map);
        final productId = args['productId'] as String;
        _purchaseCompleteHandler?.call(result, productId);
        return null;

      case 'onPassthrough':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final placementId = args['placementId'] as String;
        _passthroughHandler?.call(placementId);
        return null;

      default:
        return null;
    }
  }
}
