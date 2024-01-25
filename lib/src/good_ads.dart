import 'package:flutter/foundation.dart';

abstract class GoodAds {
  Future<void> load();

  Future<void> show({
    required OnFinishedAds onFinishedAds,
    VoidCallback? onAdShowed,
  });

  Future<bool> canShow();
}

/// Callback when an ads close, bool params is decide ads is finished show or (error/cancel)
typedef OnFinishedAds = void Function(bool showed);
