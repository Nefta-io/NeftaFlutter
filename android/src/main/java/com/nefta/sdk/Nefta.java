package com.nefta.sdk;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import java.util.HashMap;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class Nefta implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private static final String _version = "4.3.0";

    private boolean _isInitialized;
    private Context _context;
    private Handler _handler;
    private MethodChannel _sharedChannel;
    private ActivityPluginBinding _lastActivityPluginBinding;

    public static NeftaPlugin _plugin;
    public static Nefta _instance;

    @Override
    public void onAttachedToEngine(@NonNull final FlutterPluginBinding binding) {
        _context = binding.getApplicationContext();

        _plugin = NeftaPlugin._instance;

        _sharedChannel = new MethodChannel(binding.getBinaryMessenger(), "nefta");
        _sharedChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull final FlutterPluginBinding binding) {
        _sharedChannel.setMethodCallHandler(null);
    }

    private void init(final String appId, final Result result) {
        if (_isInitialized) {
            return;
        }

        _isInitialized = true;
        _handler = new Handler(Looper.getMainLooper());

        d("Initializing NeftaPlugin v" + _version + "...");

        if (TextUtils.isEmpty(appId)) {
            throw new IllegalStateException("Unable to initialize Nefta SDK - missing appId");
        }

        _plugin = NeftaPlugin.Init(_context, appId);
        _plugin._adapterCallback = this::OnInsights;
        _plugin.OnReady = (HashMap<String, Placement> placements) -> {
            d("SDK initialized" );
            result.success(true);
            _plugin.OnReady = null;
        };
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String methodName = call.method;
        if ("init".equals(methodName)) {
            String appId = call.argument("appId");
            init(appId, result);
        } else if ("enableLogging".equals(methodName)) {
            boolean enableLogging = false;
            Boolean enableLoggingBox = call.argument("enable");
            if (enableLoggingBox != null) {
                enableLogging = enableLoggingBox;
            }
            NeftaPlugin.EnableLogging(enableLogging);
        } else if ("record".equals(methodName)) {
            int type = 0;
            int category = 0;
            int subCategory = 0;
            long value = 0;

            Integer typeBox = call.argument("type");
            if (typeBox != null) {
                type = typeBox;
            }
            Integer categoryBox = call.argument("category");
            if (categoryBox != null) {
                category = categoryBox;
            }
            Integer subCategoryBox = call.argument("subCategory");
            if (subCategoryBox != null) {
                subCategory = subCategoryBox;
            }
            String name = call.argument("name");
            Number valueBox = call.argument("value");
            if (valueBox != null) {
                value = valueBox.longValue();
            }
            String customPayload = call.argument("customPayload");
            NeftaPlugin._instance.Record(type, category, subCategory, name, value, customPayload);
        } else if ("onExternalMediationRequestLoaded".equals(methodName)) {
            int adType = 0;
            Integer adTypeBox = call.argument("adType");
            if (adTypeBox != null) {
                adType = adTypeBox;
            }
            String recommendedAdUnit = call.argument("recommendedAdUnitId");
            double calculatedFloorPrice = 0;
            Double calculatedFloorPriceBox = call.argument("calculatedFloorPrice");
            if (calculatedFloorPriceBox != null) {
                calculatedFloorPrice = calculatedFloorPriceBox;
            }
            String adUnitId = call.argument("adUnitId");
            double revenue = 0;
            Double revenueBox = call.argument("revenue");
            if (revenueBox != null) {
                revenue = revenueBox;
            }
            String precision = call.argument("precision");
            onExternalMediationRequest(adType, recommendedAdUnit, calculatedFloorPrice, adUnitId, revenue, precision, 1, null, null);
        } else if ("onExternalMediationRequestFailed".equals(methodName)) {
            int adType = 0;
            Integer adTypeBox = call.argument("adType");
            if (adTypeBox != null) {
                adType = adTypeBox;
            }
            String recommendedAdUnit = call.argument("recommendedAdUnitId");
            double calculatedFloorPrice = 0;
            Double calculatedFloorPriceBox = call.argument("calculatedFloorPrice");
            if (calculatedFloorPriceBox != null) {
                calculatedFloorPrice = calculatedFloorPriceBox;
            }
            String adUnitId = call.argument("adUnitId");
            int errorCode = 0;
            Integer errorCodeBox = call.argument("errorCode");
            if (errorCodeBox != null) {
                errorCode = errorCodeBox;
            }
            int networkStatus = 0;
            Integer networkErrorCodeBox = call.argument("networkErrorCode");
            if (networkErrorCodeBox != null) {
                networkStatus = networkErrorCodeBox;
            }
            onExternalMediationRequest(adType, recommendedAdUnit, calculatedFloorPrice, adUnitId, 0, null, errorCode == 204 ? 2 : 0, String.valueOf(errorCode), String.valueOf(networkStatus));
        } else if ("onExternalMediationImpression".equals(methodName)) {
            String data = call.argument("data");
            int adType = 0;
            Integer adTypeBox = call.argument("adType");
            if (adTypeBox != null) {
                adType = adTypeBox;
            }
            double revenue = 0;
            Double revenueBox = call.argument("revenue");
            if (revenueBox != null) {
                revenue = revenueBox;
            }
            String precision = call.argument("precision");
            NeftaPlugin.OnExternalMediationImpressionAsString("applovin-max", data, adType, revenue, precision);
        } else if ("getInsights".equals(methodName)) {
            int requestId = 0;
            Integer requestIdBox = call.argument("requestId");
            if (requestIdBox != null) {
                requestId = requestIdBox;
            }
            int insights = 0;
            Integer insightsBox = call.argument("insights");
            if (insightsBox != null) {
                insights = insightsBox;
            }
            int timeout = 0;
            Integer timeoutBox = call.argument("timeout");
            if (timeoutBox != null) {
                timeout = timeoutBox;
            }
            _plugin.GetInsightsBridge(requestId, insights, timeout);
        } else if ("getNuid".equals(methodName)) {
            boolean present = false;
            Boolean presentBox = call.argument("present");
            if (presentBox != null) {
                present = presentBox;
            }
            _plugin.GetNuid(present);
        } else if ("setOverride".equals(methodName)) {
            String override = call.argument("override");
            NeftaPlugin.SetOverride(override);
        } else {
            d("unrecognized method: "+ methodName);
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull final ActivityPluginBinding binding) {
        _instance = this;
        _lastActivityPluginBinding = binding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() { }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull final ActivityPluginBinding binding) {
        _instance = this;
    }

    @Override
    public void onDetachedFromActivity() { }

    private static void onExternalMediationRequest(int adType, String recommendedAdUnitId, double calculatedFloorPrice, String adUnitId, double revenue, String precision, int status, String providerStatus, String networkStatus) {
        NeftaPlugin.OnExternalMediationRequest("applovin-max", adType, recommendedAdUnitId, -1, calculatedFloorPrice, adUnitId, revenue, precision, status, providerStatus, networkStatus);
    }

    private void OnInsights(int id, String bi) {
        _handler.post(() -> {
            _sharedChannel.invokeMethod("onInsights", new HashMap<String, Object>() {{
                put("requestId", id);
                put("insights", bi);
            }});
        });
    }

    private void d(String s) {
        Log.i("NeftaFlutter ", s);
    }
}
