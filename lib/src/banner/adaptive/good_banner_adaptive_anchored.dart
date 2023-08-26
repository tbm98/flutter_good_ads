import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_good_ads/src/local_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodBannerAdaptiveAnchored extends StatefulWidget {
  const GoodBannerAdaptiveAnchored({
    Key? key,
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.interval = 60000,
  }) : super(key: key);

  final String adUnitId;
  final AdRequest adRequest;
  final int interval;

  @override
  State<GoodBannerAdaptiveAnchored> createState() =>
      _GoodBannerAdaptiveAnchoredState();
}

class _GoodBannerAdaptiveAnchoredState
    extends State<GoodBannerAdaptiveAnchored> {
  BannerAd? _anchoredAdaptiveAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAd();
  }

  Future<void> _initAd() async {
    final lastImpressions = await getLastImpressions(widget.adUnitId);
    if (DateTime.now().millisecondsSinceEpoch - lastImpressions >
        widget.interval) {
      _loadAd();
    } else {
      // if initState but can not load immediately, delay and then load
      Future.delayed(Duration(milliseconds: widget.interval), () {
        if (_isLoaded == false) {
          _loadAd();
        }
      });
    }
  }

  Future<void> _loadAd() async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      printDebug('Unable to get height of anchored banner.');
      return;
    }

    _anchoredAdaptiveAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: widget.adRequest,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          printDebug('$ad loaded: ${ad.responseInfo}');
          setState(() {
            // When the ad is loaded, get the ad size and use it to set
            // the height of the ad container.
            _anchoredAdaptiveAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          printDebug('Anchored adaptive banner failedToLoad: $error');
          ad.dispose();
        },
        onAdImpression: (Ad ad) {
          printDebug('$ad impression: ${ad.responseInfo}');
        },
      ),
    );
    await setLastImpressions(
        widget.adUnitId, DateTime.now().millisecondsSinceEpoch);
    return _anchoredAdaptiveAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_anchoredAdaptiveAd != null && _isLoaded) {
      return SizedBox(
        width: _anchoredAdaptiveAd!.size.width.toDouble(),
        height: _anchoredAdaptiveAd!.size.height.toDouble(),
        child: AdWidget(ad: _anchoredAdaptiveAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
