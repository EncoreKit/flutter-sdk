package com.encorekit.encore_flutter_sdk

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.encorekit.encore.Encore
import com.encorekit.encore.core.canonical.user.UserAttributes
import com.encorekit.encore.core.infrastructure.logging.LogLevel
import com.encorekit.encore.features.offers.PresentationResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class EncoreFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // -- FlutterPlugin --

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.encorekit/encore")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    // -- ActivityAware --

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // -- MethodCallHandler --

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> handleConfigure(call, result)
            "identify" -> handleIdentify(call, result)
            "setUserAttributes" -> handleSetUserAttributes(call, result)
            "reset" -> handleReset(result)
            "showPlacement" -> handleShowPlacement(call, result)
            "registerOnPurchaseRequest" -> registerOnPurchaseRequest(result)
            "registerOnPurchaseComplete" -> registerOnPurchaseComplete(result)
            "registerOnPassthrough" -> registerOnPassthrough(result)
            else -> result.notImplemented()
        }
    }

    // -- Configure --

    private fun handleConfigure(call: MethodCall, result: Result) {
        val apiKey = call.argument<String>("apiKey")
        if (apiKey == null) {
            result.error("INVALID_ARGS", "apiKey is required", null)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available for configure", null)
            return
        }

        val logLevel = parseLogLevel(call.argument<String>("logLevel"))

        Encore.shared.configure(currentActivity.applicationContext, apiKey, logLevel)
        result.success(null)
    }

    // -- Identity --

    private fun handleIdentify(call: MethodCall, result: Result) {
        val userId = call.argument<String>("userId")
        if (userId == null) {
            result.error("INVALID_ARGS", "userId is required", null)
            return
        }

        val attributes = parseUserAttributes(call.argument<Map<String, Any>>("attributes"))
        Encore.shared.identify(userId, attributes)
        result.success(null)
    }

    private fun handleSetUserAttributes(call: MethodCall, result: Result) {
        val attrsMap = call.argument<Map<String, Any>>("attributes")
        if (attrsMap == null) {
            result.error("INVALID_ARGS", "attributes is required", null)
            return
        }

        val attributes = parseUserAttributes(attrsMap) ?: UserAttributes()
        Encore.shared.setUserAttributes(attributes)
        result.success(null)
    }

    // -- Reset --

    private fun handleReset(result: Result) {
        Encore.shared.reset()
        result.success(null)
    }

    // -- Placements --

    private fun handleShowPlacement(call: MethodCall, result: Result) {
        val placementId = call.argument<String>("placementId")
        val currentActivity = activity

        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available for showPlacement", null)
            return
        }

        scope.launch {
            try {
                val nativeResult = Encore.shared.placement(placementId).show(currentActivity)
                result.success(serializePresentationResult(nativeResult))
            } catch (e: Exception) {
                result.error("SHOW_FAILED", e.message, null)
            }
        }
    }

    // -- On-Demand Handler Registration --

    private fun registerOnPurchaseRequest(result: Result) {
        Encore.shared.onPurchaseRequest { purchaseRequest ->
            suspendCancellableCoroutine { continuation ->
                val fields = purchaseRequest.javaClass.declaredFields
                    .filter { it.type == String::class.java }
                    .onEach { it.isAccessible = true }
                val productId = fields.getOrNull(0)?.get(purchaseRequest) as? String ?: ""
                val placementId = fields.getOrNull(1)?.get(purchaseRequest) as? String ?: ""
                scope.launch {
                    channel.invokeMethod("onPurchaseRequest", mapOf(
                        "productId" to productId,
                        "placementId" to placementId,
                    ), object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            continuation.resume(Unit)
                        }
                        override fun error(code: String, message: String?, details: Any?) {
                            continuation.resumeWithException(
                                RuntimeException(message ?: "Purchase failed")
                            )
                        }
                        override fun notImplemented() {
                            continuation.resume(Unit)
                        }
                    })
                }
            }
        }
        result.success(null)
    }

    private fun registerOnPurchaseComplete(result: Result) {
        Encore.shared.onPurchaseComplete { billingResult, productId ->
            scope.launch {
                channel.invokeMethod("onPurchaseComplete", mapOf(
                    "result" to mapOf(
                        "productId" to billingResult.productId,
                        "purchaseToken" to billingResult.purchaseToken,
                        "orderId" to billingResult.orderId,
                    ),
                    "productId" to productId,
                ))
            }
        }
        result.success(null)
    }

    private fun registerOnPassthrough(result: Result) {
        Encore.shared.onPassthrough { placementId ->
            scope.launch {
                channel.invokeMethod("onPassthrough", mapOf(
                    "placementId" to placementId,
                ))
            }
        }
        result.success(null)
    }

    // -- Serialization Helpers --

    private fun serializePresentationResult(nativeResult: PresentationResult): Map<String, Any?> {
        return when (nativeResult) {
            is PresentationResult.Completed -> mapOf(
                "type" to "granted",
                "offerId" to nativeResult.offerId,
                "campaignId" to nativeResult.campaignId,
            )
            is PresentationResult.Dismissed -> mapOf(
                "type" to "notGranted",
                "reason" to nativeResult.reason.value,
            )
            is PresentationResult.NoOffers -> mapOf(
                "type" to "notGranted",
                "reason" to "no_offer_available",
            )
        }
    }

    private fun parseLogLevel(value: String?): LogLevel {
        return when (value?.uppercase()) {
            "DEBUG" -> LogLevel.DEBUG
            "INFO" -> LogLevel.INFO
            "WARN" -> LogLevel.WARN
            "ERROR" -> LogLevel.ERROR
            else -> LogLevel.NONE
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun parseUserAttributes(map: Map<String, Any>?): UserAttributes? {
        if (map == null || map.isEmpty()) return null

        val custom = (map["custom"] as? Map<String, String>) ?: emptyMap()

        return UserAttributes(
            email = map["email"] as? String,
            firstName = map["firstName"] as? String,
            lastName = map["lastName"] as? String,
            phoneNumber = map["phoneNumber"] as? String,
            postalCode = map["postalCode"] as? String,
            city = map["city"] as? String,
            state = map["state"] as? String,
            countryCode = map["countryCode"] as? String,
            latitude = map["latitude"] as? String,
            longitude = map["longitude"] as? String,
            dateOfBirth = map["dateOfBirth"] as? String,
            gender = map["gender"] as? String,
            language = map["language"] as? String,
            subscriptionTier = map["subscriptionTier"] as? String,
            monthsSubscribed = map["monthsSubscribed"] as? String,
            billingCycle = map["billingCycle"] as? String,
            lastPaymentAmount = map["lastPaymentAmount"] as? String,
            lastActiveDate = map["lastActiveDate"] as? String,
            totalSessions = map["totalSessions"] as? String,
            custom = custom,
        )
    }
}
