import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:applovin_max/applovin_max.dart';
import 'package:nefta_sdk_flutter/nefta.dart';

void main() {
  runApp(IntegrationDemo());
}

class IntegrationDemo extends StatelessWidget {
  const IntegrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  MainState createState() => MainState();
}

class _AdRequest {
  double? revenue;
}

class MainState extends State<MainPage> {
  final _bannerViewId = ValueKey(1);

  static final String _neftaAppId = Platform.isAndroid ? "5678631082786816" : "5727602702548992";
  static final String _dynamicInterstitialAdUnitId = Platform.isAndroid ? "084edff9524b52ec" : "fbd50dc3d655933c";
  static final String _defaultInterstitialAdUnitId = Platform.isAndroid ? "0822634ec9c39d78" : "5e11b1838778c517";
  static final String _dynamicRewardedAdUnitId = Platform.isAndroid ? "c0c516310b8c7c04" : "c068edf12c4282a6";
  static final String _defaultRewardedAdUnitId = Platform.isAndroid ? "3d7ef05a78cf8615" : "ad9b024164e61c00";

  String _interstitialStatus = "Status";
  String _rewardedStatus = "Status";
  bool _isBannerMounted = false;

  bool _isInterstitialLoadingOn = false;
  AdInsight? _dynamicInterstitialInsight;
  _AdRequest? _dynamicInterstitialRequest;
  _AdRequest? _defaultInterstitialRequest;
  int _dynamicInterstitialFails = 0;

  bool _isRewardedLoadingOn = false;
  AdInsight? _dynamicRewardedInsight;
  _AdRequest? _dynamicRewardedRequest;
  _AdRequest? _defaultRewardedRequest;
  int _dynamicRewardedFails = 0;

  @override
  void initState() {
    super.initState();

    Nefta.enableLogging(true);
    Nefta.setExtraParameter(Nefta.extParamTestGroup, "split-f");
    Nefta.init(_neftaAppId);

    initializeAds();
  }

  Future<void> initializeAds() async {
    try {
      List<String> defaultAdUnitsForPreloading = Platform.isAndroid ?
      ["084edff9524b52ec", "c0c516310b8c7c04" ] : ["fbd50dc3d655933c", "c068edf12c4282a6" ];
      AppLovinMAX.setExtraParameter("disable_b2b_ad_unit_ids", defaultAdUnitsForPreloading.join(","));
      await AppLovinMAX.initialize("IAhBswbDpMg9GhQ8NEKffzNrXQP1H4ABNFvUA7ePIz2xmarVFcy_VB8UfGnC9IPMOgpQ3p8G5hBMebJiTHv3P9");
      setState(() {
        _interstitialStatus = "Ads Initialized Successfully";
        _rewardedStatus = "Ads Initialized Successfully";
      });

      initializeInterstitial();
      initializeRewarded();
    } catch (e) {
      setState(() {
        _interstitialStatus = "Initialization Failed: $e";
        _rewardedStatus = "Initialization Failed: $e";
      });
    }
  }

  void initializeInterstitial() {
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        Nefta.onExternalMediationRequestLoaded(ad);

        if (ad.adUnitId == _dynamicInterstitialAdUnitId) {
          logInterstitial("Loaded Dynamic Interstitial ${ad.adUnitId} at ${ad.revenue}");
          _dynamicInterstitialFails = 0;
          setState(() {
            _dynamicInterstitialRequest!.revenue = ad.revenue;
          });
        } else {
          logInterstitial("Loaded Default Interstitial ${ad.adUnitId} at ${ad.revenue}");
          setState(() {
            _defaultInterstitialRequest!.revenue = ad.revenue;
          });
        }
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        Nefta.onExternalMediationRequestFailed(adUnitId, error);

        if (adUnitId == _dynamicInterstitialAdUnitId) {
          _dynamicInterstitialFails = _dynamicInterstitialFails + 1;
          int retryDelay = pow(2, min(6, _dynamicInterstitialFails)).toInt();

          logInterstitial("Load failed Dynamic Interstitial ${error.code.toString()} - retrying in ${retryDelay.toString()}s");

          Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
            if (_isInterstitialLoadingOn) {
              getInterstitialInsightAndLoad(_dynamicInterstitialInsight);
            } else {
              setState(() {
                _dynamicInterstitialRequest = null;
              });
            }
          });
        } else {
          logInterstitial("Load failed Default Interstitial code ${error.code.toString()}");

          if (_isInterstitialLoadingOn) {
            loadDefaultInterstitial();
          } else {
            setState(() {
              _defaultInterstitialRequest = null;
            });
          }
        }
      },
      onAdDisplayedCallback: (ad) {
        logInterstitial("onAdDisplayedCallback");
      },
      onAdDisplayFailedCallback: (ad, error) {
        logInterstitial("onAdDisplayFailedCallback");
      },
      onAdClickedCallback: (ad) {
        Nefta.onExternalMediationClick(ad);

        logInterstitial("onAdClickedCallback");
      },
      onAdHiddenCallback: (ad) {
        logInterstitial("onAdHiddenCallback");

        // start new cycle
        if (_isInterstitialLoadingOn) {
          startInterstitialLoading();
        }
      },
      onAdRevenuePaidCallback: (ad) {
        Nefta.onExternalMediationImpression(ad);

        logInterstitial("onAdRevenuePaidCallback: ${ad.adFormat} ${ad.revenue}");
      }
    ));
  }

  void initializeRewarded() {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
        onAdLoadedCallback: (ad) {
          Nefta.onExternalMediationRequestLoaded(ad);

          if (ad.adUnitId == _dynamicRewardedAdUnitId) {
            logRewarded("Loaded Dynamic Rewarded ${ad.adUnitId} at ${ad.revenue}");
            _dynamicRewardedFails = 0;
            setState(() {
              _dynamicRewardedRequest!.revenue = ad.revenue;
            });
          } else {
            logRewarded("Loaded Default Rewarded ${ad.adUnitId} at ${ad.revenue}");
            setState(() {
              _defaultRewardedRequest!.revenue = ad.revenue;
            });
          }
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          Nefta.onExternalMediationRequestFailed(adUnitId, error);

          if (adUnitId == _dynamicRewardedAdUnitId) {
            _dynamicRewardedFails = _dynamicRewardedFails + 1;
            int retryDelay = pow(2, min(6, _dynamicRewardedFails)).toInt();

            logRewarded("Load failed Dynamic Rewarded code ${error.code.toString()} - retrying in ${retryDelay.toString()}s");

            Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
              if (_isRewardedLoadingOn) {
                getRewardedInsightAndLoad(_dynamicRewardedInsight);
              } else {
                setState(() {
                  _dynamicRewardedRequest = null;
                });
              }
            });
          } else {
            logRewarded("Load failed Default Rewarded code ${error.code.toString()}");

            if (_isRewardedLoadingOn) {
              loadDefaultRewarded();
            } else {
              setState(() {
                _defaultRewardedRequest = null;
              });
            }
          }
        },
        onAdDisplayedCallback: (ad) {
          logRewarded("onAdDisplayedCallback");
        },
        onAdDisplayFailedCallback: (ad, error) {
          logRewarded("onAdDisplayFailedCallback");
        },
        onAdClickedCallback: (ad) {
          Nefta.onExternalMediationClick(ad);

          logRewarded("onAdClickedCallback");
        },
        onAdHiddenCallback: (ad) {
          logRewarded("onAdClickedCallback");

          // start new cycle
          if (_isRewardedLoadingOn) {
            startRewardedLoading();
          }
        },
        onAdRevenuePaidCallback: (ad) {
          Nefta.onExternalMediationImpression(ad);

          logRewarded("onAdRevenuePaidCallback: ${ad.revenue}");
        },
        onAdReceivedRewardCallback: (ad, reward) {
          logRewarded("onAdClickedCallback");
        }
    ));
  }

  void logInterstitial(String log) {
    print("NeftaPluginF Interstitial: ${log}");
    setState(() {
      _interstitialStatus = log;
    });
  }

  void logRewarded(String log) {
    print("NeftaPluginF Rewarded: ${log}");
    setState(() {
      _rewardedStatus = log;
    });
  }

  void getInterstitialInsightAndLoad(AdInsight? previousInsight) {
    setState(() {
      _dynamicInterstitialRequest = _AdRequest();
    });
    Nefta.getInsights(Insights.INTERSTITIAL, previousInsight, loadDynamicInterstitial, 5);
  }

  void loadDynamicInterstitial(Insights insights) {
    _dynamicInterstitialInsight = insights.interstitial;
    if (_dynamicInterstitialInsight != null) {
      String bidFloor = _dynamicInterstitialInsight!.floorPrice.toStringAsFixed(10);

      logInterstitial("Loading Dynamic Interstitial with floor ${bidFloor}");
      AppLovinMAX.setInterstitialExtraParameter(_dynamicInterstitialAdUnitId, "disable_auto_retries", "true");
      AppLovinMAX.setInterstitialExtraParameter(_dynamicInterstitialAdUnitId, "jC7Fp", bidFloor);
      AppLovinMAX.loadInterstitial(_dynamicInterstitialAdUnitId);

      Nefta.onExternalMediationRequest(AdType.Interstitial, _dynamicInterstitialAdUnitId, _dynamicInterstitialInsight);
    }
  }

  void loadDefaultInterstitial() {
    setState(() {
      _defaultInterstitialRequest = _AdRequest();
    });
    AppLovinMAX.loadInterstitial(_defaultInterstitialAdUnitId);

    Nefta.onExternalMediationRequest(AdType.Interstitial, _defaultInterstitialAdUnitId);
  }

  void startInterstitialLoading() {
    if (_dynamicInterstitialRequest == null) {
      getInterstitialInsightAndLoad(null);
    }
    if (_defaultInterstitialRequest == null) {
      loadDefaultInterstitial();
    }
  }

  Future<void> onInterstitialShowClick() async {
    bool isShown = false;
    if (_dynamicInterstitialRequest != null && _dynamicInterstitialRequest!.revenue != null) {
      if (_defaultInterstitialRequest != null && _defaultInterstitialRequest!.revenue != null &&
          _defaultInterstitialRequest!.revenue! > _dynamicInterstitialRequest!.revenue!) {
        isShown = await tryShowDefaultInterstitial();
      }
      if (!isShown) {
        isShown = await tryShowDynamicInterstitial();
      }
    }
    if (!isShown && _defaultInterstitialRequest != null && _defaultInterstitialRequest!.revenue != null) {
      tryShowDefaultInterstitial();
    }
  }

  Future<bool> tryShowDynamicInterstitial() async {
    bool isShown = false;
    bool isReady = (await AppLovinMAX.isInterstitialReady(_dynamicInterstitialAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showInterstitial(_dynamicInterstitialAdUnitId);
      isShown = true;
    }
    setState(() {
      _dynamicInterstitialRequest = null;
    });
    return isShown;
  }

  Future<bool> tryShowDefaultInterstitial() async {
    bool isShown = false;
    bool isReady = (await AppLovinMAX.isInterstitialReady(_defaultInterstitialAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showInterstitial(_defaultInterstitialAdUnitId);
      isShown = true;
    }
    setState(() {
      _defaultInterstitialRequest = null;
    });
    return isShown;
  }

  void startRewardedLoading() {
    if (_dynamicRewardedRequest == null) {
      getRewardedInsightAndLoad(null);
    }
    if (_defaultRewardedRequest == null) {
      loadDefaultRewarded();
    }
  }

  void getRewardedInsightAndLoad(AdInsight? previousInsight) {
    setState(() {
      _dynamicRewardedRequest = _AdRequest();
    });
    Nefta.getInsights(Insights.REWARDED, previousInsight, loadDynamicRewarded, 5);
  }

  void loadDynamicRewarded(Insights insights) {
    _dynamicRewardedInsight = insights.rewarded;
    if (insights.rewarded != null) {
      String bidFloor = _dynamicRewardedInsight!.floorPrice.toStringAsFixed(10);

      logRewarded("Loading Dynamic Rewarded with floor ${bidFloor}");
      AppLovinMAX.setRewardedAdExtraParameter(_dynamicRewardedAdUnitId, "disable_auto_retries", "true");
      AppLovinMAX.setRewardedAdExtraParameter(_dynamicRewardedAdUnitId, "jC7Fp", bidFloor);
      AppLovinMAX.loadRewardedAd(_dynamicRewardedAdUnitId);

      Nefta.onExternalMediationRequest(AdType.Rewarded, _dynamicRewardedAdUnitId, _dynamicRewardedInsight);
    }
  }

  void loadDefaultRewarded() {
    setState(() {
      _defaultRewardedRequest = _AdRequest();
    });
    AppLovinMAX.loadRewardedAd(_defaultRewardedAdUnitId);

    Nefta.onExternalMediationRequest(AdType.Rewarded, _defaultRewardedAdUnitId);
  }

  Future<void> onRewardedShowClick() async {
    bool isShown = false;
    if (_dynamicRewardedRequest != null && _dynamicRewardedRequest!.revenue != null) {
      if (_defaultRewardedRequest != null && _defaultRewardedRequest!.revenue != null &&
      _defaultRewardedRequest!.revenue! > _dynamicRewardedRequest!.revenue!) {
        isShown = await tryShowDefaultRewarded();
      }
      if (!isShown) {
        isShown = await tryShowDynamicRewarded();
      }
    }
    if (!isShown && _defaultRewardedRequest != null && _defaultRewardedRequest!.revenue != null) {
      tryShowDefaultRewarded();
    }
  }

  Future<bool> tryShowDynamicRewarded() async {
    bool isShown = false;
    bool isReady = (await AppLovinMAX.isRewardedAdReady(_dynamicRewardedAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showRewardedAd(_dynamicRewardedAdUnitId);
      isShown = true;
    }
    setState(() {
      _dynamicRewardedRequest = null;
    });
    return isShown;
  }

  Future<bool> tryShowDefaultRewarded() async {
    bool isShown = false;
    bool isReady = (await AppLovinMAX.isRewardedAdReady(_defaultRewardedAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showRewardedAd(_defaultRewardedAdUnitId);
      isShown = true;
    }
    setState(() {
      _defaultRewardedRequest = null;
    });
    return isShown;
  }

  void addDemoIntegrationExampleEvent(int type) {
    final random = Random();
    String name = "example event";
    int value = random.nextInt(101);
    if (type == 0) {
      int progressionTypeInt = random.nextInt(7);
      int statusInt = random.nextInt(3);
      int sourceInt = random.nextInt(7);
      String custom = "progression type:$progressionTypeInt status:$statusInt source:$sourceInt v:$value";

      ProgressionType progressionType = ProgressionType.fromInt(progressionTypeInt);
      ProgressionStatus status = ProgressionStatus.fromInt(statusInt);
      ProgressionSource source = ProgressionSource.fromInt(sourceInt);
      ProgressionEvent(progressionType, status, source: source, name: name, value: value, customString: custom).record();
    } else if (type == 1) {
      int categoryInt = random.nextInt(9);
      int methodInt = random.nextInt(7);
      String custom = "receive category:$categoryInt method:$methodInt v:$value";

      ResourceCategory resourceCategory = ResourceCategory.fromInt(categoryInt);
      ReceiveMethod receiveMethod = ReceiveMethod.fromInt(methodInt);
      ReceiveEvent(resourceCategory, method: receiveMethod, name: name, value: value, customString: custom).record();
    } else {
      int categoryInt = random.nextInt(9);
      int methodInt = random.nextInt(7);
      String custom = "spend category:$categoryInt method:$methodInt v:$value";

      ResourceCategory resourceCategory = ResourceCategory.fromInt(categoryInt);
      SpendMethod spendMethod = SpendMethod.fromInt(methodInt);
      SpendEvent(resourceCategory, method: spendMethod, name: name, value: value, customString: custom).record();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TableRow 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Load Interstitial"),
                    Switch(
                        value: _isInterstitialLoadingOn,
                        onChanged: (value) {
                          if (value) {
                            startInterstitialLoading();
                          }

                          setState(() {
                            _isInterstitialLoadingOn = value;
                          });

                          addDemoIntegrationExampleEvent(2);
                        }),
                    SizedBox(width: 10),
                    _buildButton("Show Interstitial", _dynamicInterstitialRequest != null && _dynamicInterstitialRequest!.revenue != null ||
                        _defaultInterstitialRequest != null && _defaultInterstitialRequest!.revenue != null ? onInterstitialShowClick : null),
                  ],
                ),
                // TableRow 2
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(5),
                  child: Text(
                    _interstitialStatus,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // TableRow 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Load Rewarded"),
                    Switch(
                      value: _isRewardedLoadingOn,
                        onChanged: (value) {
                          if (value) {
                            startRewardedLoading();
                          }

                          setState(() {
                            _isRewardedLoadingOn = value;
                          });

                          addDemoIntegrationExampleEvent(2);
                        }),
                    SizedBox(width: 10),
                    _buildButton("Show Rewarded", (_dynamicRewardedRequest != null && _dynamicRewardedRequest!.revenue != null ||
                        _defaultRewardedRequest != null && _defaultRewardedRequest!.revenue != null) ? onRewardedShowClick : null),
                  ],
                ),
                // TableRow 4
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(5),
                  child: Text(
                    _rewardedStatus,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPress) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Color(0xff7d3ba2)),
        child: Text(text, style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
