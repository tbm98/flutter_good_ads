import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pool/pool.dart';

import 'good_ads.dart';

class GoodInterstitial extends GoodAds {
  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  GoodInterstitial({
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.interval = 60000,
    required this.onPaidEvent,
    required this.onAdImpression,
    required this.onAdFailedToLoad,
  });

  InterstitialAd? interstitialAd;
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
    return interstitialAd != null &&
        _isloaded &&
        DateTime.now().millisecondsSinceEpoch - await getLastImpressions(adUnitId) > interval;
  }

  bool get needLoad => interstitialAd == null && _isLoading == false && _isloaded == false;

  static final pool = Pool(1);

  /// load ads with retry
  @override
  Future<AdWithoutView?> load({bool useRetry = true}) async {
    return await pool.withResource(() async {
      if (!needLoad) {
        return interstitialAd;
      }
      interstitialAd?.dispose();
      _isLoading = true;
      final result = useRetry ? await retry(_loadRaw) : await _loadRaw();
      _isLoading = false;
      return result;
    });
  }

  Future<InterstitialAd?> _loadRaw() async {
    final Completer<InterstitialAd?> result = Completer();
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          printInfo('Interstitial:onAdLoaded($adUnitId): ${ad.print()}');
          interstitialAd = ad;
          _isloaded = true;
          result.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          printInfo('Interstitial:onAdFailedToLoad($adUnitId): ${error.toString()}');
          onAdFailedToLoad.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId, error);
          interstitialAd?.dispose();
          interstitialAd = null;
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
    if (await canShow()) {
      interstitialAd!.onPaidEvent = onPaidEvent;
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          printInfo('Interstitial:onAdShowedFullScreenContent($adUnitId): ${ad.print()}');
          onAdShowed?.call();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          printInfo('Interstitial:onAdDismissedFullScreenContent($adUnitId): ${ad.print()}');
          _isloaded = false;
          onFinishedAds(true);
          ad.dispose();
          interstitialAd = null;
          load();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          printInfo(
              'Interstitial:onAdFailedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
          _isloaded = false;
          onAdFailedToShow?.call();
          onFinishedAds(false);
          ad.dispose();
          interstitialAd = null;
          load();
        },
        onAdImpression: (InterstitialAd ad) {
          printInfo('Interstitial:onAdImpression($adUnitId): ${ad.print()}');
          onAdImpression.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId,
              ad.responseInfo?.responseId ?? '');
        },
      );
      await interstitialAd!.show();
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    } else {
      onFinishedAds(false);
      load();
    }
  }
}
