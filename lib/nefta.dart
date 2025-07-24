import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:applovin_max/applovin_max.dart';

import 'Insights.dart';

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

  Nefta();

  static void enableLogging(bool enable) {
    _methodChannel.invokeMethod('enableLogging', { 'enable': enable});
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

  static void getInsights(int insights, Function(Insights) callback, [int timeoutInSeconds=0]) {
    _callbackRegistry[_requestId] = callback;
    _methodChannel.invokeMapMethod('getInsights', {
      "requestId": _requestId,
      "insights": insights,
      "timeout": timeoutInSeconds
    });
    _requestId++;
  }

  static Future<void> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onInsights') {
      final int requestId = call.arguments['requestId'];
      final String insightsString = call.arguments['insights'];

      Insights insights = Insights();

      final Map<String, dynamic> data = jsonDecode(insightsString);
      if (data.containsKey("churn")) {
        final Map<String, dynamic> churnData = data['churn'];
        Churn churn = Churn();
        churn.d1_probability = churnData["d1_probability"] as double;
        churn.d3_probability = churnData["d3_probability"] as double;
        churn.d7_probability = churnData["d7_probability"] as double;
        churn.d14_probability = churnData["d14_probability"] as double;
        churn.d30_probability = churnData["d30_probability"] as double;
        churn.probability_confidence = churnData["probability_confidence"] as String;
        insights.churn = churn;
      }

      if (data.containsKey("floor_price")) {
        final  Map<String, dynamic> floorPrices = data["floor_price"];
        if (floorPrices.containsKey("banner_configuration")) {
          final bannerData = floorPrices['banner_configuration'] as Map<String, dynamic>;
          insights.banner = AdInsight(AdType.Banner, (bannerData["floor_price"] as num).toDouble(), bannerData["ad_unit"]);
        }
        if (floorPrices.containsKey("interstitial_configuration")) {
          final interstitialData = floorPrices['interstitial_configuration'] as Map<String, dynamic>;
          insights.interstitial = AdInsight(AdType.Interstitial, (interstitialData["floor_price"] as num).toDouble(), interstitialData["ad_unit"]);
        }
        if (floorPrices.containsKey("rewarded_configuration")) {
          final rewardedData = floorPrices['rewarded_configuration'] as Map<String, dynamic>;
          insights.rewarded = AdInsight(AdType.Rewarded, (rewardedData["floor_price"] as num).toDouble(), rewardedData["ad_unit"]);
        }
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

  static void onExternalMediationRequestLoaded(AdType adType, AdInsight? insight, MaxAd? ad) {
    String? recommendedAdUnitId;
    double calculatedFloorPrice = 0;
    if (insight != null) {
      recommendedAdUnitId = insight.adUnit;
      calculatedFloorPrice = insight.floorPrice;
    }
    String? adUnitId = null;
    double revenue = 0;
    String? precision = null;
    if (ad != null) {
      adUnitId = ad.adUnitId;
      revenue = ad.revenue;
      precision = ad.revenuePrecision;
    }
    _methodChannel.invokeMapMethod('onExternalMediationRequestLoaded', {
      "adType": adType.index,
      "recommendedAdUnitId": recommendedAdUnitId,
      "calculatedFloorPrice": calculatedFloorPrice,
      "adUnitId": adUnitId,
      "revenue": revenue,
      "precision": precision
    });
  }

  static void onExternalMediationRequestFailed(AdType adType, AdInsight? insight, String adUnitId, MaxError error) {
    String? recommendedAdUnitId;
    double calculatedFloorPrice = 0;
    if (insight != null) {
      recommendedAdUnitId = insight.adUnit;
      calculatedFloorPrice = insight.floorPrice;
    }
    int networkCode = 0;
    _methodChannel.invokeMapMethod('onExternalMediationRequestFailed', {
      "adType": adType.index,
      "recommendedAdUnitId": recommendedAdUnitId,
      "calculatedFloorPrice": calculatedFloorPrice,
      "adUnitId": adUnitId,
      "errorCode": error.code.value,
      "networkErrorCode": networkCode
    });
  }

  static void onExternalMediationImpression(MaxAd? ad) {
    if (ad != null) {
      int adType = AdType.Other.value;
      String adFormat = ad.adFormat.toLowerCase();
      if (adFormat == "banner" || adFormat == "leader" || adFormat == "leaderboard" || adFormat == "mrec") {
        adType = AdType.Banner.value;
      } else if (adFormat == "inter" || adFormat == "interstitial") {
        adType = AdType.Interstitial.value;
      } else if (adFormat == "reward" || adFormat == "rewarded") {
        adType = AdType.Rewarded.value;
      }
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
        "data": jsonEncode(data),
        "adType": adType,
        "revenue": ad.revenue,
        "precision": ad.revenuePrecision
      });
    }
  }
}