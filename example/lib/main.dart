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

enum AdState {
  Idle,
  Loading,
  Ready
}

class MainState extends State<MainPage> {
  final _bannerViewId = ValueKey(1);

  static final String _neftaAppId = Platform.isAndroid ? "5678631082786816" : "5727602702548992";
  static final String _defaultBannerAdUnitId = Platform.isAndroid ? "d3d61616c344d2b4" : "78161f678bc0c46f";
  static final String _defaultInterstitialAdUnitId = Platform.isAndroid ? "0822634ec9c39d78" : "5e11b1838778c517";
  static final String _defaultRewardedAdUnitId = Platform.isAndroid ? "3d7ef05a78cf8615" : "ad9b024164e61c00";

  static final List<String> _adUnits = Platform.isAndroid ?
      ["0822634ec9c39d78", "084edff9524b52ec", "3d7ef05a78cf8615", "c0c516310b8c7c04" ] :
      ["5e11b1838778c517", "fbd50dc3d655933c", "ad9b024164e61c00", "c068edf12c4282a6" ];

  String _bannerAdUnitId = _defaultBannerAdUnitId;
  String _interstitialAdUnitId = _defaultInterstitialAdUnitId;
  String _rewardedAdUnitId = _defaultRewardedAdUnitId;

  String _statusText = "Status";
  bool _isBannerMounted = false;
  AdInsight? _interstitialInsight;
  AdState _interstitialState = AdState.Idle;
  int _interstitialRetryAttempt = 0;
  AdInsight? _rewardedInsight;
  AdState _rewardedState = AdState.Idle;
  int _rewardedRetryAttempt = 0;

  @override
  void initState() {
    super.initState();

    Nefta.enableLogging(true);
    Nefta.init(_neftaAppId);

    initializeAds();
  }

  Future<void> initializeAds() async {
    try {
      AppLovinMAX.setExtraParameter("disable_b2b_ad_unit_ids", _adUnits.join(","));
      await AppLovinMAX.initialize("IAhBswbDpMg9GhQ8NEKffzNrXQP1H4ABNFvUA7ePIz2xmarVFcy_VB8UfGnC9IPMOgpQ3p8G5hBMebJiTHv3P9");
      setState(() {
        _statusText = "Ads Initialized Successfully";
      });

      initializeBanner();
      initializeInterstitial();
      initializeRewarded();
    } catch (e) {
      setState(() {
        _statusText = "Initialization Failed: $e";
      });
    }
  }

  void onCloseBannerClick() {
    AppLovinMAX.destroyBanner(_bannerAdUnitId);
    setState(() {
      _isBannerMounted = false;
    });
  }

  void initializeBanner() {
    AppLovinMAX.setBannerListener(
        AdViewAdListener(
            onAdLoadedCallback: (ad) {
              log("Banner loaded: ${ad.networkName}");
              setState(() {
                _isBannerMounted = true;
              });
            },
            onAdLoadFailedCallback: (adUnitId, error) {
              log("Banner failed to load: ${error.message}");
            },
            onAdClickedCallback: (ad) {
              log("Banner clicked");
            },
            onAdExpandedCallback: (ad) {
              log("Banner expanded");
            },
            onAdCollapsedCallback: (ad) {
              log("Banner collapsed");
            },
            onAdRevenuePaidCallback: (ad) {
              log("Banner revenue paid: ${ad.revenue}");
            }
        )
    );
  }

  void initializeInterstitial() {
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        Nefta.onExternalMediationRequestLoaded(AdType.Interstitial, _interstitialInsight, ad);

        log("Interstitial ad loaded from ${ad.networkName}");
        _interstitialRetryAttempt = 0;
        setState(() {
          _interstitialState = AdState.Ready;
        });
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        Nefta.onExternalMediationRequestFailed(AdType.Interstitial, _interstitialInsight, adUnitId, error);

        _interstitialRetryAttempt = _interstitialRetryAttempt + 1;
        if (_interstitialRetryAttempt > 6) return;
        int retryDelay = pow(2, min(6, _interstitialRetryAttempt)).toInt();

        log("Interstitial ad failed to load with code ${error.code.toString()} - retrying in ${retryDelay.toString()}s");

        Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
          if (_interstitialState == AdState.Loading) {
            getInterstitialInsightAndLoad();
          }
        });
      },
      onAdDisplayedCallback: (ad) {
        log("onAdDisplayedCallback");
      },
      onAdDisplayFailedCallback: (ad, error) {
        log("onAdDisplayFailedCallback");
      },
      onAdClickedCallback: (ad) {
        log("onAdClickedCallback");
      },
      onAdHiddenCallback: (ad) {
        log("onAdHiddenCallback");
      },
      onAdRevenuePaidCallback: (ad) {
        Nefta.onExternalMediationImpression(ad);

        log("onAdRevenuePaidCallback: ${ad.adFormat} ${ad.revenue}");
      }
    ));
  }

  void initializeRewarded() {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
        onAdLoadedCallback: (ad) {
          Nefta.onExternalMediationRequestLoaded(AdType.Rewarded, _rewardedInsight, ad);

          log("Rewarded ad loaded from ${ad.networkName}");
          _rewardedRetryAttempt = 0;
          setState(() {
            _rewardedState = AdState.Ready;
          });
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          Nefta.onExternalMediationRequestFailed(AdType.Rewarded, _rewardedInsight, adUnitId, error);

          _rewardedRetryAttempt = _rewardedRetryAttempt + 1;
          if (_rewardedRetryAttempt > 6) return;
          int retryDelay = pow(2, min(6, _rewardedRetryAttempt)).toInt();
          log("Rewarded ad failed to load with code ${error.code.toString()} - retrying in ${retryDelay.toString()}s");

          Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
            if (_rewardedState == AdState.Loading) {
              getRewardedInsightAndLoad();
            }
          });
        },
        onAdDisplayedCallback: (ad) {
          log("onAdDisplayedCallback");
        },
        onAdDisplayFailedCallback: (ad, error) {
          log("onAdDisplayFailedCallback");
        },
        onAdClickedCallback: (ad) {
          log("onAdClickedCallback");
        },
        onAdHiddenCallback: (ad) {
          log("onAdClickedCallback");
        },
        onAdRevenuePaidCallback: (ad) {
          Nefta.onExternalMediationImpression(ad);

          log("onAdRevenuePaidCallback: ${ad.revenue}");
        },
        onAdReceivedRewardCallback: (ad, reward) {
          log("onAdClickedCallback");
        }
    ));
  }

  void log(String log) {
    print(log);
    setState(() {
      _statusText = log;
    });
  }

  void onShowBannerClick() {
    _bannerAdUnitId = _defaultBannerAdUnitId;

    AppLovinMAX.createBanner(_bannerAdUnitId, AdViewPosition.topCenter, false);
    AppLovinMAX.stopBannerAutoRefresh(_bannerAdUnitId);

    AppLovinMAX.loadBanner(_bannerAdUnitId);

    log("load banner");
    addDemoIntegrationExampleEvent(1);
  }

  void getInterstitialInsightAndLoad() {
    Nefta.getInsights(Insights.INTERSTITIAL, loadInterstitial, 5);
  }

  void loadInterstitial(Insights insights) {
    _interstitialAdUnitId = _defaultInterstitialAdUnitId;

    _interstitialInsight = insights.interstitial;
    if (_interstitialInsight != null) {
      if (_interstitialInsight!.adUnit != null && _interstitialInsight!.adUnit!.isNotEmpty) {
        _interstitialAdUnitId = _interstitialInsight!.adUnit!;
      }
    }

    AppLovinMAX.setInterstitialExtraParameter(_interstitialAdUnitId, "disable_auto_retries", "true");
    AppLovinMAX.loadInterstitial(_interstitialAdUnitId);
  }

  void onInterstitialLoadClick() {
    if (_interstitialState == AdState.Loading) {
      setState(() {
        _interstitialState = AdState.Idle;
      });
    } else {
      getInterstitialInsightAndLoad();
      setState(() {
        _interstitialState = AdState.Loading;
      });
      addDemoIntegrationExampleEvent(1);
    }
  }

  Future<void> onInterstitialShowClick() async {
    bool isReady = (await AppLovinMAX.isInterstitialReady(_interstitialAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showInterstitial(_interstitialAdUnitId);
    }
    setState(() {
      _interstitialState = AdState.Idle;
    });
  }

  void getRewardedInsightAndLoad() {
    Nefta.getInsights(Insights.REWARDED, loadRewarded, 5);
  }

  void loadRewarded(Insights insights) {
    _rewardedAdUnitId = _defaultRewardedAdUnitId;

    _rewardedInsight = insights.rewarded;
    if (_rewardedInsight != null) {
      if (_rewardedInsight!.adUnit != null && _rewardedInsight!.adUnit!.isNotEmpty) {
        _rewardedAdUnitId = _rewardedInsight!.adUnit!;
      }
    }

    AppLovinMAX.setRewardedAdExtraParameter(_rewardedAdUnitId, "disable_auto_retries", "true");
    AppLovinMAX.loadRewardedAd(_rewardedAdUnitId);
  }

  void onRewardedLoadClick() {
    if (_rewardedState == AdState.Loading) {
      setState(() {
        _rewardedState = AdState.Idle;
      });
    } else {
      getRewardedInsightAndLoad();
      setState(() {
        _rewardedState = AdState.Loading;
      });
      addDemoIntegrationExampleEvent(2);
    }
  }

  Future<void> onRewardedShowClick() async {
    bool isReady = (await AppLovinMAX.isRewardedAdReady(_rewardedAdUnitId))!;
    if (isReady) {
      AppLovinMAX.showRewardedAd(_rewardedAdUnitId);
    }
    setState(() {
      _rewardedState = AdState.Idle;
    });
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
                // BannerView
                if (_isBannerMounted)
                  Container(
                    key: _bannerViewId,
                    width: 320,
                    height: 50,
                    color: Colors.blue,
                    alignment: Alignment.center,
                    child: MaxAdView(
                      adUnitId: _bannerAdUnitId,
                      adFormat: AdFormat.banner
                    )
                  )
                else
                  Container(
                    key: _bannerViewId,
                    width: 320,
                    height: 50,
                    color: Colors.blue,
                    alignment: Alignment.center,
                  )
                ,
                // LeaderView (hidden by default)
                Visibility(
                  visible: false,
                  child: Container(
                    width: 728,
                    height: 90,
                    color: Colors.blue,
                    alignment: Alignment.center,
                  ),
                ),
                // TableLayout equivalent
                Transform.translate(
                  offset: Offset(0, 100),
                  child: Column(
                    children: [
                      // TableRow 1
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton("Show Banner", onShowBannerClick),
                          SizedBox(width: 10),
                          _buildButton("Close Banner", _isBannerMounted ? onCloseBannerClick : null),
                        ],
                      ),
                      // TableRow 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(_interstitialState == AdState.Idle ? "Load Interstitial" : "Cancel",
                              _interstitialState != AdState.Ready ? onInterstitialLoadClick : null),
                          SizedBox(width: 10),
                          _buildButton("Show Interstitial", _interstitialState == AdState.Ready ? onInterstitialShowClick : null),
                        ],
                      ),
                      // TableRow 3
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(_rewardedState == AdState.Idle ? "Load Rewarded" : "Cancel",
                              _rewardedState != AdState.Ready ? onRewardedLoadClick : null),
                          SizedBox(width: 10),
                          _buildButton("Show Rewarded", _rewardedState == AdState.Ready ? onRewardedShowClick : null),
                        ],
                      ),
                      // TableRow 4
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(5),
                        child: Text(
                          _statusText,
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
