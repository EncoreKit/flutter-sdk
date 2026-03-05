import Flutter
import UIKit
import Encore

public class EncoreFlutterPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.encorekit/encore",
            binaryMessenger: registrar.messenger()
        )
        let instance = EncoreFlutterPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - MethodChannel Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "configure":
            handleConfigure(args: args, result: result)
        case "identify":
            handleIdentify(args: args, result: result)
        case "setUserAttributes":
            handleSetUserAttributes(args: args, result: result)
        case "reset":
            handleReset(result: result)
        case "showPlacement":
            handleShowPlacement(args: args, result: result)
        case "registerOnPurchaseRequest":
            registerOnPurchaseRequest(result: result)
        case "registerOnPurchaseComplete":
            registerOnPurchaseComplete(result: result)
        case "registerOnPassthrough":
            registerOnPassthrough(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Configure

    private func handleConfigure(args: [String: Any]?, result: @escaping FlutterResult) {
        guard let apiKey = args?["apiKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "apiKey is required", details: nil))
            return
        }

        let logLevel = parseLogLevel(args?["logLevel"] as? String)

        Encore.shared.configure(apiKey: apiKey, logLevel: logLevel)
        result(nil)
    }

    // MARK: - Identity

    private func handleIdentify(args: [String: Any]?, result: @escaping FlutterResult) {
        guard let userId = args?["userId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "userId is required", details: nil))
            return
        }

        let attributes = parseUserAttributes(args?["attributes"] as? [String: Any])
        Encore.shared.identify(userId: userId, attributes: attributes)
        result(nil)
    }

    private func handleSetUserAttributes(args: [String: Any]?, result: @escaping FlutterResult) {
        guard let attrsMap = args?["attributes"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "attributes is required", details: nil))
            return
        }

        let attributes = parseUserAttributes(attrsMap)
        Encore.shared.setUserAttributes(attributes ?? UserAttributes())
        result(nil)
    }

    // MARK: - Reset

    private func handleReset(result: @escaping FlutterResult) {
        Encore.shared.reset()
        result(nil)
    }

    // MARK: - Placements

    private func handleShowPlacement(args: [String: Any]?, result: @escaping FlutterResult) {
        let placementId = args?["placementId"] as? String

        Task { @MainActor in
            do {
                let nativeResult = try await Encore.shared.placement(placementId).show()
                result(self.serializePresentationResult(nativeResult))
            } catch {
                result(FlutterError(
                    code: "SHOW_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    // MARK: - On-Demand Handler Registration

    private func registerOnPurchaseRequest(result: @escaping FlutterResult) {
        Encore.shared.onPurchaseRequest { [weak self] productId, placementId in
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.main.async {
                    self?.channel.invokeMethod("onPurchaseRequest", arguments: [
                        "productId": productId,
                        "placementId": placementId ?? "",
                    ]) { response in
                        if let error = response as? FlutterError {
                            continuation.resume(throwing: NSError(
                                domain: "EncoreFlutter",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: error.message ?? "Purchase failed"]
                            ))
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
        }
        result(nil)
    }

    private func registerOnPurchaseComplete(result: @escaping FlutterResult) {
        Encore.shared.onPurchaseComplete { [weak self] transaction, productId in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onPurchaseComplete", arguments: [
                    "result": [
                        "productId": productId,
                        "transactionId": String(transaction.id),
                    ],
                    "productId": productId,
                ])
            }
        }
        result(nil)
    }

    private func registerOnPassthrough(result: @escaping FlutterResult) {
        Encore.shared.onPassthrough { [weak self] placementId in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onPassthrough", arguments: [
                    "placementId": placementId ?? "",
                ])
            }
        }
        result(nil)
    }

    // MARK: - Serialization Helpers

    private func serializePresentationResult(_ nativeResult: PresentationResult) -> [String: Any] {
        switch nativeResult {
        case .granted:
            return ["type": "granted"]
        case .notGranted(let reason):
            return ["type": "notGranted", "reason": reason.rawValue]
        @unknown default:
            return ["type": "notGranted", "reason": "unknown"]
        }
    }

    private func parseLogLevel(_ value: String?) -> Encore.LogLevel {
        switch value?.uppercased() {
        case "DEBUG": return .debug
        case "INFO": return .info
        case "WARN": return .warn
        case "ERROR": return .error
        default: return .none
        }
    }

    private func parseUserAttributes(_ map: [String: Any]?) -> UserAttributes? {
        guard let map = map, !map.isEmpty else { return nil }

        var customDict: [String: String] = [:]
        if let custom = map["custom"] as? [String: String] {
            customDict = custom
        }

        return UserAttributes(
            email: map["email"] as? String,
            firstName: map["firstName"] as? String,
            lastName: map["lastName"] as? String,
            phoneNumber: map["phoneNumber"] as? String,
            postalCode: map["postalCode"] as? String,
            city: map["city"] as? String,
            state: map["state"] as? String,
            countryCode: map["countryCode"] as? String,
            latitude: map["latitude"] as? String,
            longitude: map["longitude"] as? String,
            dateOfBirth: map["dateOfBirth"] as? String,
            gender: map["gender"] as? String,
            language: map["language"] as? String,
            subscriptionTier: map["subscriptionTier"] as? String,
            monthsSubscribed: map["monthsSubscribed"] as? String,
            billingCycle: map["billingCycle"] as? String,
            lastPaymentAmount: map["lastPaymentAmount"] as? String,
            lastActiveDate: map["lastActiveDate"] as? String,
            totalSessions: map["totalSessions"] as? String,
            custom: customDict
        )
    }
}
