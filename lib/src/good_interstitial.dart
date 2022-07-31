import 'dart:async';

import 'package:andesgroup_common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodInterstitial {
  const GoodInterstitial._();

  static Map<String, int> lastImpressions = {};
  static final Map<String, InterstitialAd> _instance = {};
  static final Map<String, int> _interval = {};

  /// return [InterstitialAd], or throw [LoadAdError] if error
  ///
  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  static Future<InterstitialAd> load({
    required String adUnitId,
    required AdRequest adRequest,
    int interval = 60000,
  }) async {
    _interval[adUnitId] = interval;
    final Completer<InterstitialAd> result = Completer();
    await InterstitialAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) => debug(
                  'interstitial_showedFullScreenContent($adUnitId): ${ad.print()}'),
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                debug(
                    'interstitial_dismissedFullScreenContent($adUnitId): ${ad.print()}');
                ad.dispose();
                _instance.remove(adUnitId);
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError error) {
                debug(
                    'interstitial_failedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
                ad.dispose();
                _instance.remove(adUnitId);
              },
              onAdImpression: (InterstitialAd ad) =>
                  debug('interstitial_impression($adUnitId): ${ad.print()}'),
            );
            _instance[adUnitId] = ad;
            debug('interstitial_loaded($adUnitId): ${ad.print()}');
            result.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debug(
                'interstitial_failedToLoaded($adUnitId): ${error.toString()}');
            result.completeError(error);
          },
        ));
    return result.future;
  }

  /// show the InterstitialAd by [adUnitId], must call [load] first.
  ///
  /// if [reloadAfterShow] is not null, it will automatically call reload for
  /// you after show.
  static Future<void> show({
    required String adUnitId,
    VoidCallback? reloadAfterShow,
  }) async {
    // Ad instance of adUnitId has loaded fail or already showed.
    if (_instance[adUnitId] == null) {
      reloadAfterShow?.call();
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - lastImpressions.get(adUnitId) >
        _interval.get(adUnitId)) {
      await _instance[adUnitId]!.show();
      lastImpressions.set(adUnitId, DateTime.now().millisecondsSinceEpoch);
      reloadAfterShow?.call();
    }
  }
}
