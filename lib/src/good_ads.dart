import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class GoodAds {
  Future<AdWithoutView?> load({required bool useRetry});

  Future<void> show({
    required OnFinishedAds onFinishedAds,
    VoidCallback? onAdShowed,
  });

  Future<bool> canShow();
}

/// Callback when an ads close, bool params is decide ads is finished show or (error/cancel)
typedef OnFinishedAds = void Function(bool showed);
