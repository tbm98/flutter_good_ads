import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_good_ads/src/extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodBanner extends StatefulWidget {
  static Map<String, int> lastImpressions = {};

  /// [interval] minimum interval between 2 impressions (millis), default: 60000
  const GoodBanner({
    Key? key,
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.adSize = AdSize.banner,
    this.interval = 60000,
  }) : super(key: key);

  final String adUnitId;
  final AdRequest adRequest;
  final AdSize adSize;
  final int interval;

  @override
  State<GoodBanner> createState() => _GoodBannerState();
}

class _GoodBannerState extends State<GoodBanner> {
  late final BannerAdListener listener = BannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) {
      printDebug('banner_loaded(${widget.adUnitId}): ${ad.responseInfo.toString()}');
      GoodBanner.lastImpressions
          .set(widget.adUnitId, DateTime.now().millisecondsSinceEpoch);
    },
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      printDebug(
          'banner_load_failed(${widget.adUnitId}): ${ad.responseInfo.toString()}, Error: ${error.toString()}');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => printDebug(
        'banner_opened(${widget.adUnitId}): ${ad.responseInfo.toString()}'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => printDebug(
        'banner_closed(${widget.adUnitId}): ${ad.responseInfo.toString()}'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => printDebug(
        'banner_impression(${widget.adUnitId}): ${ad.responseInfo.toString()}'),
  );

  late final BannerAd myBanner = BannerAd(
    adUnitId: widget.adUnitId,
    size: widget.adSize,
    request: widget.adRequest,
    listener: listener,
  );

  bool hasLoadAd = false;

  @override
  void initState() {
    super.initState();
    if (DateTime.now().millisecondsSinceEpoch -
            GoodBanner.lastImpressions.get(widget.adUnitId) >
        widget.interval) {
      loadAd();
    } else {
      // if initState but can not load immediately, delay and then load
      Future.delayed(Duration(milliseconds: widget.interval), () {
        if (hasLoadAd == false) {
          loadAd();
        }
      });
    }
  }

  Future<void> loadAd() async {
    await myBanner.load();
    GoodBanner.lastImpressions
        .set(widget.adUnitId, DateTime.now().millisecondsSinceEpoch);
    setState(() {
      hasLoadAd = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasLoadAd) {
      return Container(
        alignment: Alignment.center,
        width: myBanner.size.width.toDouble(),
        height: myBanner.size.height.toDouble(),
        child: AdWidget(ad: myBanner),
      );
    } else {
      return const SizedBox();
    }
  }
}
