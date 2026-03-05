# Encore Flutter SDK -- Product Requirements Document

## Overview

The Encore Flutter SDK is a plugin that enables Flutter apps to use the Encore monetization platform by bridging to the existing native iOS and Android SDK binaries. All offer UI, billing, analytics, and entitlement logic runs natively -- the Flutter layer is a thin coordination bridge via platform channels.

## Problem

Encore provides native SDKs for iOS (Swift, distributed as `Encore.xcframework`) and Android (Kotlin, distributed as AAR via Maven). Apps built with Flutter could not use Encore because there was no Dart interface to these native binaries.

## Solution

A Flutter plugin package (`encore_flutter_sdk`) that:

1. Wraps the native Encore SDKs via Flutter's `MethodChannel`
2. Exposes an idiomatic Dart API mirroring the native SDK surface
3. Preserves all native SDK behavior including server-driven UI, StoreKit/Play Billing integration, analytics, and A/B experiments

## Architecture

```
Flutter App (Dart)
       |
       v
Encore Dart API (lib/src/encore.dart)
       |
       v
MethodChannel (com.encorekit/encore)
       |
  +---------+---------+
  |                   |
  v                   v
iOS Plugin          Android Plugin
(Swift)             (Kotlin)
  |                   |
  v                   v
Encore.xcframework  com.encorekit:encore AAR
```

### Key Design Decisions

- **MethodChannel over FFI**: The native SDKs have complex internal state (networking, UI presentation, StoreKit observers, analytics sinks). MethodChannel delegates to the existing singleton instances rather than trying to replicate or bind at the memory level.
- **On-demand handler registration**: Native callback handlers (`onPurchaseRequest`, `onPurchaseComplete`, `onPassthrough`) are only registered on the native SDK when the Dart side explicitly sets them. This preserves the native SDK's fallback behavior (e.g., native StoreKit purchase modal when no purchase handler is set).
- **Native UI**: All offer sheets, Safari views, and purchase modals are rendered by the native SDKs. The Flutter plugin triggers presentation and receives results -- no Flutter UI is involved.

## Dart Public API

| Method | Description |
|--------|-------------|
| `Encore.shared.configure(apiKey:, logLevel:)` | Initialize the SDK |
| `Encore.shared.identify(userId:, attributes:)` | Associate user identity |
| `Encore.shared.setUserAttributes(attributes)` | Merge user attributes |
| `Encore.shared.reset()` | Clear user data (logout) |
| `Encore.shared.placement(id).show()` | Present native offer sheet, returns `PresentationResult` |
| `Encore.shared.onPurchaseRequest(handler)` | Delegate purchases to a Flutter-side subscription manager |
| `Encore.shared.onPurchaseComplete(handler)` | Observe native billing completions (fallback path) |
| `Encore.shared.onPassthrough(handler)` | Handle not-granted outcomes |

## Capabilities Inherited from Native SDKs

The following run entirely inside the native binaries with no Flutter-side implementation:

- **Server-driven UI**: Offer sheet layouts fetched from remote config and rendered natively (SwiftUI on iOS, Jetpack Compose on Android)
- **IAP integration**: StoreKit (iOS) and Play Billing (Android) product lookups, pricing display, and purchase flows
- **IAP-First flow**: Triggering a subscription purchase before showing offers when configured
- **A/B experiments**: NCL cohort assignment, ghost triggers for control groups, exposure logging
- **Analytics**: PostHog and backend event sinks
- **Entitlements**: Provisional and verified entitlement tracking
- **Remote configuration**: UI config variants, entitlement config, experiment config

## IAP / Purchase Flow

Two paths are supported:

### Delegated (recommended for apps using RevenueCat, Adapty, etc.)

1. Dart sets `onPurchaseRequest`
2. Native SDK determines the `iapProductId` from remote config
3. Native SDK calls the handler with `(productId, placementId)`
4. Flutter app purchases via its own subscription manager
5. Native SDK is not involved in the actual billing transaction

### Native Fallback (no handler set)

1. Dart does NOT set `onPurchaseRequest`
2. Native SDK determines the `iapProductId` from remote config
3. Native SDK fetches StoreKit/Play Billing product details and presents the native purchase modal
4. `onPurchaseComplete` fires with the transaction result (if Dart set that handler)

## File Structure

```
encore-flutter-sdk/
├── pubspec.yaml                          # Package definition, plugin registration
├── lib/
│   ├── encore_flutter_sdk.dart           # Barrel export
│   └── src/
│       ├── encore.dart                   # Encore class, PlacementBuilder
│       ├── encore_platform_channel.dart  # MethodChannel bridge
│       └── models/
│           ├── user_attributes.dart
│           ├── presentation_result.dart
│           ├── log_level.dart
│           └── billing_purchase_result.dart
├── ios/
│   ├── encore_flutter_sdk.podspec        # Depends on EncoreKit pod
│   └── Classes/
│       └── EncoreFlutterPlugin.swift     # iOS bridge (Swift -> Encore.xcframework)
├── android/
│   ├── build.gradle                      # Depends on com.encorekit:encore AAR
│   └── src/main/kotlin/.../
│       └── EncoreFlutterPlugin.kt        # Android bridge (Kotlin -> Encore AAR)
├── example/                              # Demo app
├── test/                                 # Dart unit tests
└── README.md                             # Installation and usage docs
```

## Distribution

| Platform | Mechanism | Native Dependency |
|----------|-----------|-------------------|
| iOS | CocoaPods (via Flutter plugin podspec) | `EncoreKit` pod -> `Encore.xcframework` |
| Android | Gradle (via plugin build.gradle) | `com.encorekit:encore:1.4.0` AAR from Maven |
| Dart | Git dependency or pub.dev | `encore_flutter_sdk` package |

## Testing

- **Dart unit tests**: Model serialization (`PresentationResult.fromMap`, `UserAttributes.toMap`, etc.)
- **iOS simulator**: Requires StoreKit Configuration file on Xcode scheme for IAP testing. Run from Xcode, not `flutter run`, for StoreKit to work.
- **Integration**: Run the example app with a valid API key to exercise the full flow (configure -> identify -> show placement -> claim offer -> purchase)

## Limitations

- StoreKit testing on simulator requires launching from Xcode (not `flutter run`) due to StoreKit Configuration injection
- `onPurchaseComplete` on iOS serializes limited `StoreKit.Transaction` fields (`transactionId`, `productId`) -- apps needing full transaction data should use `onPurchaseRequest` with a Flutter-side IAP library
- No Flutter-side UI -- all offer rendering is native. Custom Flutter UI overlays are not supported.
