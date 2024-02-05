import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class GoodAdsFullScreen {
  static bool isShowing = false;

  Future<AdWithoutView?> load({bool useRetry = true});

  Future<void> show({
    required OnFinishedAds onFinishedAds,
    VoidCallback? onAdShowed,
    VoidCallback? onAdFailedToShow,
  });

  Future<bool> canShow();
}

/// Callback when an ads close, bool params is decide ads is finished show or (error/cancel)
typedef OnFinishedAds = void Function(bool showed);
