import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodInterstitial {
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
  final OnPaidEventCallback onPaidEvent;
  final void Function(int time, String adUnitId) onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error) onAdFailedToLoad;

  Future<bool> canShow() async {
    return interstitialAd != null &&
        _isloaded &&
        DateTime.now().millisecondsSinceEpoch - await getLastImpressions(adUnitId) > interval;
  }

  /// load ads with retry
  Future<void> load() async {
    interstitialAd?.dispose();
    await retry(_loadRaw);
  }

  Future<void> _loadRaw() async {
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          printDebug('Interstitial:onAdLoaded($adUnitId): ${ad.print()}');
          interstitialAd = ad;
          _isloaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          printDebug('Interstitial:onAdFailedToLoad($adUnitId): ${error.toString()}');
          onAdFailedToLoad.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId, error);
          interstitialAd?.dispose();
          interstitialAd = null;
          _isloaded = false;
        },
      ),
    );
  }

  /// show the InterstitialAd by [adUnitId], must call [load] first.
  Future<void> show({
    required VoidCallback onAdClosed,
  }) async {
    if (await canShow()) {
      interstitialAd!.onPaidEvent = onPaidEvent;
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) =>
            printInfo('Interstitial:onAdShowedFullScreenContent($adUnitId): ${ad.print()}'),
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          printInfo('Interstitial:onAdDismissedFullScreenContent($adUnitId): ${ad.print()}');
          _isloaded = false;
          onAdClosed();
          ad.dispose();
          load();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          printInfo(
              'Interstitial:onAdFailedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
          _isloaded = false;
          onAdClosed();
          ad.dispose();
          load();
        },
        onAdImpression: (InterstitialAd ad) {
          printInfo('Interstitial:onAdImpression($adUnitId): ${ad.print()}');
          onAdImpression.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId);
        },
      );
      await interstitialAd!.show();
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    } else {
      onAdClosed();
      load();
    }
  }
}
