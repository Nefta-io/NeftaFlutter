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
    private static final String _version = "4.4.0";
    private static final String _provider = "applovin-max";

    private boolean _isInitialized;
    private Context _context;
    private Handler _handler;
    private MethodChannel _sharedChannel;
    private ActivityPluginBinding _lastActivityPluginBinding;
    private AdapterListener _listener;

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

        if (TextUtils.isEmpty(appId)) {
            throw new IllegalStateException("Unable to initialize Nefta SDK - missing appId");
        }

        _listener = new AdapterListener(this::IOnInsights);

        _plugin = NeftaPlugin.Init(_context, appId);
        _plugin._adapterCallback = _listener;
        _plugin.OnReady = (InitConfiguration initConfig) -> {
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
        } else if ("setExtraParameter".equals(methodName)) {
            String key = call.argument("key");
            String value = call.argument("value");
            NeftaPlugin.SetExtraParameter(key, value);
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
        } else if ("onExternalMediationRequest".equals(methodName)) {
            int adType = 0;
            Integer adTypeBox = call.argument("adType");
            if (adTypeBox != null) {
                adType = adTypeBox;
            }
            String id = call.argument("id");
            String requestedAdUnitId = call.argument("requestedAdUnitId");
            double requestedFloorPrice = 0;
            Double requestedFloorPriceBox = call.argument("requestedFloorPrice");
            if (requestedFloorPriceBox != null) {
                requestedFloorPrice = requestedFloorPriceBox;
            }
            int adOpportunityId = 0;
            Integer adOpportunityIdBox = call.argument("adOpportunityId");
            if (adOpportunityIdBox != null) {
                adOpportunityId = adOpportunityIdBox;
            }
            NeftaPlugin.OnExternalMediationRequest(_provider, adType, id, requestedAdUnitId, requestedFloorPrice, adOpportunityId);
        } else if ("onExternalMediationResponse".equals(methodName)) {
            String id = call.argument("id");
            double revenue = 0;
            Double revenueBox = call.argument("revenue");
            if (revenueBox != null) {
                revenue = revenueBox;
            }
            String precision = call.argument("precision");
            int status = 0;
            Integer statusBox = call.argument("status");
            if (statusBox != null) {
                status = statusBox;
            }
            String providerStatus = call.argument("providerStatus");
            NeftaPlugin.OnExternalMediationResponse(_provider, id, null, revenue, precision, status, providerStatus, null);
        } else if ("onExternalMediationImpression".equals(methodName)) {
            boolean isClick = false;
            Boolean isClickBox = call.argument("isClick");
            if (isClickBox != null) {
                isClick = isClickBox;
            }
            String data = call.argument("data");
            String id = call.argument("id");
            NeftaPlugin.OnExternalMediationImpressionAsString(isClick, _provider, data, id, null);
        } else if ("getInsights".equals(methodName)) {
            int requestId = 0;
            Integer requestIdBox = call.argument("requestId");
            if (requestIdBox != null) {
                requestId = requestIdBox;
            }
            int previousAdOpportunity = -1;
            Integer previousAdOpportunityBox = call.argument("adOpportunityId");
            if (previousAdOpportunityBox != null) {
                previousAdOpportunity = previousAdOpportunityBox;
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
            _plugin.GetInsightsBridge(requestId, insights, previousAdOpportunity, timeout);
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

    private void d(String s) {
        Log.i("NeftaFlutter ", s);
    }


    private void IOnInsights(int requestId, int adapterResponseType, String adapterResponse) {
        _handler.post(() -> {
            _sharedChannel.invokeMethod("onInsights", new HashMap<String, Object>() {{
                put("requestId", requestId);
                put("adapterResponseType", adapterResponseType);
                put("adapterResponse", adapterResponse);
            }});
        });
    }
}
