import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:applovin_max/applovin_max.dart';

import 'insights.dart';

export 'package:nefta_sdk_flutter/insights.dart';
export 'package:nefta_sdk_flutter/game_event.dart';

enum AdType {
  Other(0),
  Banner(1),
  Interstitial(2),
  Rewarded(3);

  final int value;

  const AdType(this.value);
}

class Nefta {

  static const MethodChannel _methodChannel = MethodChannel('nefta');

  static bool _hasInitializeInvoked = false;
  static final Completer<bool> _initializeCompleter = Completer<bool>();

  static const String extParamTestGroup = "test_group";
  static const String extParamAttributionSource = "attribution_source";
  static const String extParamAttributionCampaign = "attribution_campaign";
  static const String extParamAttributionAdset = "attribution_adset";
  static const String extParamAttributionCreative = "attribution_creative";
  static const String extParamAttributionIncentivized = "attribution_incentivized";

  Nefta();

  static void enableLogging(bool enable) {
    _methodChannel.invokeMethod('enableLogging', { 'enable': enable});
  }

  static void setExtraParameter(String key, String value) {
    _methodChannel.invokeMethod('setExtraParameter', { 'key': key, 'value': value });
  }

  static void override(String override) {
    _methodChannel.invokeMethod('setOverride', { 'override': override });
  }

  static Future<bool> init(String appId) async {
    if (_hasInitializeInvoked) {
      return _initializeCompleter.future;
    }

    _hasInitializeInvoked = true;

    _methodChannel.setMethodCallHandler(_handleNativeCallback);

    try {
      await _methodChannel.invokeMethod('init', { 'appId': appId});

      _initializeCompleter.complete(true);
      return _initializeCompleter.future;
    } catch (e, stack) {
      if (!_initializeCompleter.isCompleted) {
        _initializeCompleter.completeError(e, stack);
      }
      return false;
    }
  }

  static final Map<int, Function(Insights)> _callbackRegistry = {};
  static int _requestId = 0;

  static void getInsights(int insights, AdInsight? previousInsight, Function(Insights) callback, [int timeoutInSeconds=0]) {
    _callbackRegistry[_requestId] = callback;
    int previousAdOpportunity = -1;
    if (previousInsight != null) {
      previousAdOpportunity = previousInsight.adOpportunityId;
    }
    _methodChannel.invokeMapMethod('getInsights', {
      "requestId": _requestId,
      "adOpportunityId": previousAdOpportunity,
      "insights": insights,
      "timeout": timeoutInSeconds
    });
    _requestId++;
  }

  static Future<void> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onInsights') {
      final int requestId = call.arguments['requestId'];
      final int adapterResponseType = call.arguments['adapterResponseType'];
      final String insightsString = call.arguments['adapterResponse'];

      Insights insights = Insights();

      final Map<String, dynamic> data = jsonDecode(insightsString);
      if (adapterResponseType == Insights.CHURN) {
        Churn churn = Churn();
        churn.d1_probability = data["d1_probability"] as double;
        churn.d3_probability = data["d3_probability"] as double;
        churn.d7_probability = data["d7_probability"] as double;
        churn.d14_probability = data["d14_probability"] as double;
        churn.d30_probability = data["d30_probability"] as double;
        churn.probability_confidence = data["probability_confidence"] as String;
        insights.churn = churn;
      } else if (adapterResponseType == Insights.BANNER) {
        double floor = (data["floor_price"] as num).toDouble();
        String? recommendedAdUnit = data["ad_unit"];
        int adOpportunityId = data["ad_opportunity_id"];
        insights.banner = AdInsight(AdType.Banner, floor, recommendedAdUnit, adOpportunityId);
      } else if (adapterResponseType == Insights.INTERSTITIAL) {
        double floor = (data["floor_price"] as num).toDouble();
        String? recommendedAdUnit = data["ad_unit"];
        int adOpportunityId = data["ad_opportunity_id"];
        insights.interstitial = AdInsight(AdType.Interstitial, floor, recommendedAdUnit, adOpportunityId);
      } else if (adapterResponseType == Insights.REWARDED) {
        double floor = (data["floor_price"] as num).toDouble();
        String? recommendedAdUnit = data["ad_unit"];
        int adOpportunityId = data["ad_opportunity_id"];
        insights.rewarded = AdInsight(AdType.Rewarded, floor, recommendedAdUnit, adOpportunityId);
      }

      final callback = _callbackRegistry.remove(requestId);
      if (callback != null) {
        callback(insights);
      }
    }
  }

  static void Record(int type, int category, int subCategory, String? name, int value, String? customPayload) {
    _methodChannel.invokeMapMethod('record', {
      "type": type,
      "category": category,
      "subCategory": subCategory,
      "name": name,
      "value": value,
      "customPayload": customPayload
    });
  }

  static void onExternalMediationRequest(AdType adType, String requestedAdUnitId, [AdInsight? usedInsight, double customBidFloor=-1]) {
    int adOpportunityId = -1;
    if (usedInsight != null) {
      adOpportunityId = usedInsight.adOpportunityId;
      if (customBidFloor < 0) {
        customBidFloor = usedInsight.floorPrice;
      }
    }
    _methodChannel.invokeMapMethod('onExternalMediationRequest', {
      "adType": adType.index,
      "id": requestedAdUnitId,
      "requestedAdUnitId": requestedAdUnitId,
      "requestedFloorPrice": customBidFloor,
      "adOpportunityId": adOpportunityId,
    });
  }

  static void onExternalMediationRequestLoaded(MaxAd? ad) {
    String? adUnitId;
    double revenue = 0;
    String? precision;
    if (ad != null) {
      adUnitId = ad.adUnitId;
      revenue = ad.revenue;
      precision = ad.revenuePrecision;
    }

    Nefta._onExternalMediationResponse(adUnitId!, revenue, precision, 1, null);
  }

  static void onExternalMediationRequestFailed(String adUnitId, MaxError error) {
    int providerStatus = error.code.value;
    Nefta._onExternalMediationResponse(adUnitId, -1, null, providerStatus == 204 ? 2 : 0, providerStatus.toString());
  }

  static void _onExternalMediationResponse(String id, double revenue, String? precision, int status, String? providerStatus) {
    _methodChannel.invokeMapMethod('onExternalMediationResponse', {
      "id": id,
      "revenue": revenue,
      "precision": precision,
      "status": status,
      "providerStatus": providerStatus
    });
  }

  static void onExternalMediationImpression(MaxAd? ad) {
    _onImpression(false, ad);
  }

  static void onExternalMediationClick(MaxAd? ad) {
    _onImpression(true, ad);
  }

  static void _onImpression(bool isClick, MaxAd? ad) {
    if (ad != null) {
      Map<String, dynamic> data = {
        'ad_unit_id': ad.adUnitId,
        'placement_name': ad.placement,
        'format': ad.adFormat,
        'dsp_name': ad.dspName,
        'creative_id': ad.creativeId,
        'request_latency': ad.latencyMillis,
        'revenue': ad.revenue,
        'precision': ad.revenuePrecision
      };

      data['waterfall_name'] = ad.waterfall.name;
      data['waterfall_test_name'] = ad.waterfall.testName;
      List<String> waterfall = [];
      for (var i = 0; i < ad.waterfall.networkResponses.length; i++) {
        waterfall.add(ad.waterfall.networkResponses[i].mediatedNetwork.name);
      }
      data['waterfall'] = waterfall;

      _methodChannel.invokeMapMethod('onExternalMediationImpression', {
        "isClick": isClick,
        "data": jsonEncode(data),
        "id": ad.adUnitId
      });
    }
  }
}