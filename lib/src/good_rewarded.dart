import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodRewarded {
  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  GoodRewarded({
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.interval = 60000,
    required this.onPaidEvent,
    required this.onAdImpression,
    required this.onAdFailedToLoad,
  });

  RewardedAd? rewardedAd;
  final String adUnitId;
  final AdRequest adRequest;
  final int interval;
  bool _isloaded = false;
  bool _isLoading = false;
  final OnPaidEventCallback onPaidEvent;
  final void Function(int time, String adUnitId) onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error) onAdFailedToLoad;

  Future<bool> canShow() async {
    return rewardedAd != null &&
        _isloaded &&
        DateTime.now().millisecondsSinceEpoch - await getLastImpressions(adUnitId) > interval;
  }

  bool get needLoad => rewardedAd == null && _isLoading == false && _isloaded == false;

  /// load ads with retry
  Future<void> load() async {
    if (!needLoad) {
      return;
    }
    rewardedAd?.dispose();
    _isLoading = true;
    await retry(_loadRaw);
    _isLoading = false;
  }

  /// return [RewardedAd], or throw [LoadAdError] if error
  Future<RewardedAd?> _loadRaw() async {
    final Completer<RewardedAd?> result = Completer();
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          printInfo('REWARDED:onAdLoaded($adUnitId): ${ad.print()}');
          rewardedAd = ad;
          _isloaded = true;
          result.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          printInfo('REWARDED:onAdFailedToLoad($adUnitId): ${error.toString()}');
          onAdFailedToLoad.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId, error);
          rewardedAd?.dispose();
          rewardedAd = null;
          _isloaded = false;
          result.complete(null);
        },
      ),
    );
    return await result.future;
  }

  /// show the InterstitialAd by [adUnitId], must call [load] first.
  Future<void> show({
    required void Function(AdWithoutView? ad, RewardItem? reward) onUserEarnedReward,
  }) async {
    if (await canShow()) {
      rewardedAd!.onPaidEvent = onPaidEvent;
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) =>
            printInfo('REWARDED:onAdShowedFullScreenContent($adUnitId): ${ad.print()}'),
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          printInfo('REWARDED:onAdDismissedFullScreenContent($adUnitId): ${ad.print()}');
          _isloaded = false;
          onUserEarnedReward(null, null);
          ad.dispose();
          rewardedAd = null;
          load();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          printInfo(
              'REWARDED:onAdFailedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
          _isloaded = false;
          onUserEarnedReward(null, null);
          ad.dispose();
          rewardedAd = null;
          load();
        },
        onAdImpression: (RewardedAd ad) {
          printInfo('REWARDED:onAdImpression($adUnitId): ${ad.print()}');
          onAdImpression.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId);
        },
      );
      await rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    } else {
      onUserEarnedReward(null, null);
      load();
    }
  }
}
