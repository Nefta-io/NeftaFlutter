import 'nefta.dart';

class Insights {
  static const int NONE = 0;
  static const int CHURN = 1 << 0;
  static const int BANNER = 1 << 1;
  static const int INTERSTITIAL = 1 << 2;
  static const int REWARDED = 1 << 3;

  Churn? churn;
  AdInsight? banner;
  AdInsight? interstitial;
  AdInsight? rewarded;
}

class Churn {
  double d1_probability = 0;
  double d3_probability = 0;
  double d7_probability = 0;
  double d14_probability = 0;
  double d30_probability = 0;
  String? probability_confidence = null;
}

class AdInsight {
  AdType type = AdType.Other;
  double floorPrice = 0;
  String? adUnit = null;

  AdInsight(AdType type, double floorPrice, String? adUnit) {
    this.type = type;
    this.floorPrice = floorPrice;
    this.adUnit = adUnit;
  }

  @override
  String toString() {
    return "AdInsight[type: ${type}, recommendedAdUnit: ${adUnit}, floorPrice: ${floorPrice}]";
  }
}