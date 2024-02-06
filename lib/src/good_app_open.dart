import 'dart:async';

import 'package:flutter/foundation.dart';

import '../flutter_good_ads.dart';

class GoodAppOpen {
  GoodAppOpen({
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    required this.onPaidEvent,
    required this.onAdLoaded,
    required this.onAdClicked,
    required this.onAdImpression,
    required this.onAdFailedToLoad,
  });

  final String adUnitId;
  final AdRequest adRequest;
  final OnPaidEventCallback onPaidEvent;
  final void Function(int time, String adUnitId, String responseId) onAdLoaded;
  final void Function(int time, String adUnitId, String responseId) onAdClicked;
  final void Function(int time, String adUnitId, String responseId) onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error) onAdFailedToLoad;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  /// Load an AppOpenAd.
  Future<AppOpenAd?> load() {
    final result = Completer<AppOpenAd?>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      orientation: AppOpenAd.orientationPortrait,
      request: adRequest,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
          result.complete(_appOpenAd);
          onAdLoaded(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId,
              ad.responseInfo?.responseId ?? '');
        },
        onAdFailedToLoad: (error) {
          // Handle the error.
          onAdFailedToLoad(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId, error);
          result.complete(null);
        },
      ),
    );
    return result.future;
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  Future<void> show({
    required OnFinishedAds onFinishedAds,
    VoidCallback? onAdShowed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (GoodAdsFullScreen.isShowing) {
      GoodAdsFullScreen.isShowing = false;
      return;
    }
    if (GoodAdsFullScreen.isShowing) {
      return;
    }
    if (!isAdAvailable) {
      load();
      return;
    }
    if (_isShowingAd) {
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      load();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.onPaidEvent = onPaidEvent;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (AppOpenAd ad) {
        onAdClicked(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId,
            ad.responseInfo?.responseId ?? '');
      },
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        onAdShowed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        onAdFailedToShow?.call();
        onFinishedAds(false);
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        onFinishedAds(true);
        ad.dispose();
        _appOpenAd = null;
        load();
      },
      onAdImpression: (ad) {
        onAdImpression(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId,
            ad.responseInfo?.responseId ?? '');
      },
    );
    await _appOpenAd!.show();
  }
}
