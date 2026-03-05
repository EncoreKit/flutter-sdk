## 1.0.0

* Initial release.
* Platform channel bridge to native Encore iOS (XCFramework) and Android (AAR) SDKs.
* `Encore.shared.configure`, `identify`, `setUserAttributes`, `reset`.
* `Encore.shared.placement(id).show()` with `PresentationResult`.
* `onPurchaseRequest` with async handler support (native SDK waits for completion).
* `onPurchaseComplete` for native StoreKit/Play Billing fallback purchases.
* `onPassthrough` for not-granted outcomes.
* On-demand handler registration preserving native SDK fallback behavior.
