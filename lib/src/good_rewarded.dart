import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodRewarded {
  static Map<String, int> lastImpressions = {};
  static final Map<String, RewardedAd> _instance = {};
  static final Map<String, int> _interval = {};

  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  const GoodRewarded({
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.interval = 60000,
  });

  final String adUnitId;
  final AdRequest adRequest;
  final int interval;

  /// return [RewardedAd], or throw [LoadAdError] if error
  Future<RewardedAd> load() async {
    _interval[adUnitId] = interval;
    final Completer<RewardedAd> result = Completer();
    await RewardedAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) => printDebug('interstitial_showedFullScreenContent($adUnitId): ${ad.print()}'),
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                printDebug('interstitial_dismissedFullScreenContent($adUnitId): ${ad.print()}');
                ad.dispose();
                _instance.remove(adUnitId);
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                printDebug('interstitial_failedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
                ad.dispose();
                _instance.remove(adUnitId);
              },
              onAdImpression: (RewardedAd ad) => printDebug('interstitial_impression($adUnitId): ${ad.print()}'),
            );
            _instance[adUnitId] = ad;
            printDebug('interstitial_loaded($adUnitId): ${ad.print()}');
            result.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            printDebug('interstitial_failedToLoaded($adUnitId): ${error.toString()}');
            result.completeError(error);
          },
        ));
    return result.future;
  }

  /// show the InterstitialAd by [adUnitId], must call [load] first.
  ///
  /// if [reloadAfterShow] is true, it will automatically call reload for
  /// you after show. default: true
  Future<void> show({
    bool reloadAfterShow = true,
    void Function(AdWithoutView, RewardItem)? onUserEarnedReward,
    Function? onError,
  }) async {
    // Ad instance of adUnitId has loaded fail or already showed.
    if (_instance[adUnitId] == null) {
      if (onError != null) {
        onError();
      }
      if (reloadAfterShow) {
        load();
      }

      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - lastImpressions.get(adUnitId) > _interval.get(adUnitId)) {
      await _instance[adUnitId]!.show(
        onUserEarnedReward: onUserEarnedReward ?? (_, __) {},
      );
      lastImpressions.set(adUnitId, DateTime.now().millisecondsSinceEpoch);
      if (reloadAfterShow) {
        load();
      }
    }
    else {
      if (onError != null) {
        onError();
      }
    }
  }
}
