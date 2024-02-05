import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_good_ads/flutter_good_ads.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:pool/pool.dart';

class GoodRewarded extends GoodAdsFullScreen {
  static final Map<int, (AdWithoutView, RewardItem)> _rewarded = {};

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
  final void Function(int time, String adUnitId, String responseId) onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error) onAdFailedToLoad;

  @override
  Future<bool> canShow() async {
    return rewardedAd != null &&
        _isloaded &&
        DateTime.now().millisecondsSinceEpoch - await getLastImpressions(adUnitId) > interval;
  }

  bool get needLoad => rewardedAd == null && _isLoading == false && _isloaded == false;

  static final pool = Pool(1);

  /// load ads with retry
  @override
  Future<AdWithoutView?> load({bool useRetry = true}) async {
    return await pool.withResource(() async {
      if (!needLoad) {
        return rewardedAd;
      }
      rewardedAd?.dispose();
      _isLoading = true;
      final result = useRetry ? await retry(_loadRaw) : await _loadRaw();
      _isLoading = false;
      return result;
    });
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
  @override
  Future<void> show({
    required OnFinishedAds onFinishedAds,
    VoidCallback? onAdShowed,
    VoidCallback? onAdFailedToShow,
  }) async {
    final showAt = DateTime.now().millisecondsSinceEpoch;

    if (await canShow()) {
      rewardedAd!.onPaidEvent = onPaidEvent;
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          printInfo('REWARDED:onAdShowedFullScreenContent($adUnitId): ${ad.print()}');
          onAdShowed?.call();
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          printInfo('REWARDED:onAdDismissedFullScreenContent($adUnitId): ${ad.print()}');
          _isloaded = false;
          onFinishedAds(_rewarded[showAt] != null);
          _rewarded.clear();
          ad.dispose();
          rewardedAd = null;
          load();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          printInfo(
              'REWARDED:onAdFailedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
          _isloaded = false;
          onAdFailedToShow?.call();
          onFinishedAds(false);
          _rewarded.clear();
          ad.dispose();
          rewardedAd = null;
          load();
        },
        onAdImpression: (RewardedAd ad) {
          printInfo('REWARDED:onAdImpression($adUnitId): ${ad.print()}');
          onAdImpression.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId,
              ad.responseInfo?.responseId ?? '');
        },
      );
      await rewardedAd!.show(onUserEarnedReward: (adWithoutView, rewardItem) {
        _rewarded[showAt] = (adWithoutView, rewardItem);
      });
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    } else {
      onFinishedAds(false);
      load();
    }
  }
}
