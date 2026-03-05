# Encore Flutter SDK

Flutter plugin wrapping the native Encore iOS and Android SDKs. All offer UI is rendered natively — this plugin bridges configuration, identity, placement presentation, and callback handling via platform channels.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  encore_flutter_sdk:
    git:
      url: https://github.com/EncoreKit/encore-flutter-sdk.git
      ref: main
```

### iOS

The plugin depends on `EncoreKit` via CocoaPods. Your app's `ios/Podfile` must include the EncoreKit pod source. The plugin's podspec handles the dependency automatically.

Minimum deployment target: **iOS 15.0**.

### Android

The plugin depends on `com.encorekit:encore` via Maven. Add the EncoreKit Maven repository to your app's `android/build.gradle`:

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.pkg.github.com/EncoreKit/android") }
    }
}
```

Minimum SDK: **21**.

## Usage

### Configure

Call once early in your app lifecycle (e.g., in `main()` or your root widget's `initState`):

```dart
import 'package:encore_flutter_sdk/encore_flutter_sdk.dart';

await Encore.shared.configure(
  apiKey: 'your_api_key',
  logLevel: LogLevel.debug,
);
```

### Register Handlers

Set up handlers before presenting offers:

```dart
Encore.shared.onPurchaseRequest((purchaseRequest) {
  // Purchase Request includes:
  // purchaseRequest.productId
  // purchaseRequest.promoId
  // purchaseRequest.placementId
  // Trigger purchase via your subscription manager (RevenueCat, etc.)
});

Encore.shared.onPassthrough((placementId) {
  // Encore didn't result in a purchase — run your original button logic
});

// Optional: only fires when no onPurchaseRequest handler is set
Encore.shared.onPurchaseComplete((result, productId) {
  print('Native purchase completed: ${result.productId}');
});
```

### Identify User

After authentication:

```dart
await Encore.shared.identify(
  userId: 'user_123',
  attributes: UserAttributes(
    email: 'user@example.com',
    subscriptionTier: 'premium',
  ),
);
```

### Update Attributes

```dart
await Encore.shared.setUserAttributes(
  UserAttributes(billingCycle: 'annual'),
);
```

### Present Offers

```dart
final result = await Encore.shared.placement('cancel_flow').show();

switch (result) {
  case PresentationResultGranted(:final offerId):
    print('Offer granted: $offerId');
  case PresentationResultNotGranted(:final reason):
    print('Not granted: $reason');
}
```

### Reset (Logout)

```dart
await Encore.shared.reset();
```

## Architecture

```
Flutter App
    │
    ▼
┌─────────────────────────────┐
│  Encore Dart API            │
│  (lib/src/encore.dart)      │
├─────────────────────────────┤
│  MethodChannel              │
│  com.encorekit/encore       │
├──────────────┬──────────────┤
│  iOS Plugin  │ Android Plugin│
│  (Swift)     │ (Kotlin)     │
├──────────────┼──────────────┤
│  Encore      │ com.encorekit│
│  .xcframework│ :encore AAR  │
└──────────────┴──────────────┘
```

The Dart layer sends method calls to the native plugins, which delegate to the native Encore SDK singletons. Native-to-Dart callbacks (purchase requests, passthrough) are forwarded via reverse method invocations on the same channel.

## API Reference

| Method | Description |
|--------|-------------|
| `Encore.shared.configure(apiKey:, logLevel:)` | Initialize the SDK |
| `Encore.shared.identify(userId:, attributes:)` | Associate user identity |
| `Encore.shared.setUserAttributes(attributes)` | Merge user attributes |
| `Encore.shared.reset()` | Clear user data (logout) |
| `Encore.shared.placement(id).show()` | Present native offer sheet |
| `Encore.shared.onPurchaseRequest(handler)` | Handle purchase delegation |
| `Encore.shared.onPurchaseComplete(handler)` | Handle native purchase completion |
| `Encore.shared.onPassthrough(handler)` | Handle not-granted outcomes |
