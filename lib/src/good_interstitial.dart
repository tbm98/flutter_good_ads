import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodInterstitial {
  static final Map<String, InterstitialAd> _instance = {};
  static final Map<String, int> _interval = {};
  static final Map<String, bool> _reloadAfterShow = {};

  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  const GoodInterstitial({
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
  final void Function(String, LoadAdError)? onAdFailedToLoad;

  Future<bool> load() async {
    _interval[adUnitId] = interval;
    final Completer<bool> result = Completer();
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) => printDebug(
                'interstitial_showedFullScreenContent($adUnitId): ${ad.print()}'),
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              printDebug(
                  'interstitial_dismissedFullScreenContent($adUnitId): ${ad.print()}');
              ad.dispose();
              _instance.remove(adUnitId);
              if (_reloadAfterShow[adUnitId] ?? true) {
                load();
              }
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              printDebug(
                  'interstitial_failedToShowFullScreenContent($adUnitId): ${ad.print()},Error: $error');
              ad.dispose();
              _instance.remove(adUnitId);
              if (_reloadAfterShow[adUnitId] ?? true) {
                load();
              }
            },
            onAdImpression: (InterstitialAd ad) {
              printDebug('interstitial_impression($adUnitId): ${ad.print()}');
              onAdImpression?.call(
                  DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId);
            },
          );
          _instance[adUnitId] = ad;
          printDebug('interstitial_loaded($adUnitId): ${ad.print()}');
          result.complete(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          printDebug(
              'interstitial_failedToLoaded($adUnitId): ${error.toString()}');
          onAdFailedToLoad?.call(adUnitId, error);
          _instance.remove(adUnitId);
          result.complete(false);
        },
      ),
    );
    return result.future;
  }

  /// show the InterstitialAd by [adUnitId], must call [load] first.
  ///
  /// if [reloadAfterShow] is true, it will automatically call reload for
  /// you after show. default: true
  Future<void> show({
    bool reloadAfterShow = true,
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
      await _instance[adUnitId]!.show();
      await setLastImpressions(adUnitId, DateTime.now().millisecondsSinceEpoch);
    }
  }
}
