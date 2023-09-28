import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodRewarded {
  static final Map<String, RewardedAd> _instance = {};
  static final Map<String, int> _interval = {};
  static final Map<String, bool> _reloadAfterShow = {};

  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  const GoodRewarded({
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.interval = 60000,
    this.onAdImpression,
    this.onAdFailedToLoad,
  });

  final String adUnitId;
  final AdRequest adRequest;
  final int interval;
  final void Function(int time, String adUnitId)? onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error)?
      onAdFailedToLoad;

  /// return [RewardedAd], or throw [LoadAdError] if error
  Future<bool> load() async {
    _interval[adUnitId] = interval;
    final Completer<bool> result = Completer();
    await RewardedAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) => printDebug(
                  'onAdShowedFullScreenContent($adUnitId): ${ad.print()}'),
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                printDebug(
                    'onAdDismissedFullScreenContent($adUnitId): ${ad.print()}');
                ad.dispose();
                _instance.remove(adUnitId);
                if (_reloadAfterShow[adUnitId] ?? true) {
                  load();
                }
              },
              onAdFailedToShowFullScreenContent:
                  (RewardedAd ad, AdError error) {
                printDebug(
                    'onAdFailedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
                ad.dispose();
                _instance.remove(adUnitId);
                if (_reloadAfterShow[adUnitId] ?? true) {
                  load();
                }
              },
              onAdImpression: (RewardedAd ad) {
                printDebug('onAdImpression($adUnitId): ${ad.print()}');
                onAdImpression?.call(
                    DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId);
              },
            );
            _instance[adUnitId] = ad;
            printDebug('onAdLoaded($adUnitId): ${ad.print()}');
            result.complete(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            printDebug('onAdFailedToLoad($adUnitId): ${error.toString()}');
            onAdFailedToLoad?.call(
                DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId, error);
            _instance.remove(adUnitId);
            result.complete(false);
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
  }) async {
    _reloadAfterShow[adUnitId] = reloadAfterShow;
    // Ad instance of adUnitId has loaded fail or already showed.
    if (_instance[adUnitId] == null) {
      if (reloadAfterShow) {
        load();
      }
      return;
    }

    if (DateTime.now().millisecondsSinceEpoch -
            await getLastImpressions(adUnitId) >
        _interval.get(adUnitId)) {
      await _instance[adUnitId]!
          .show(onUserEarnedReward: onUserEarnedReward ?? (_, __) {});
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    }
  }
}
