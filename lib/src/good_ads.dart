import 'package:flutter/foundation.dart';

import '../flutter_good_ads.dart';

abstract class GoodAds {
  Future<void> load();

  Future<void> show({
    VoidCallback? onAdClosed,
    void Function(AdWithoutView? ad, RewardItem? reward)? onUserEarnedReward,
  });
}
