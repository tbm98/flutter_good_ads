import 'package:google_mobile_ads/google_mobile_ads.dart';

extension OnMapInt on Map<String, int> {
  int get(String id) {
    return this[id] ?? 0;
  }

  void set(String id, int value) {
    this[id] = value;
  }
}

extension PrintInterstitial on InterstitialAd {
  String print() {
    return responseInfo.toString();
  }
}



extension PrintRewardedAd on RewardedAd {
  String print() {
    return responseInfo.toString();
  }
}
