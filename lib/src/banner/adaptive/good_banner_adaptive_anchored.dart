import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoodBannerAdaptiveAnchored extends StatefulWidget {
  const GoodBannerAdaptiveAnchored({
    super.key,
    required this.adUnitId,
    this.adRequest = const AdRequest(),
    this.adsPlaceholderColor,
    this.onLoadAdError,
    this.onAdImpression,
    this.onAdFailedToLoad,
    required this.placeHolder,
  });

  final String? adUnitId;
  final AdRequest adRequest;
  final Color? adsPlaceholderColor;
  final void Function(Object, StackTrace)? onLoadAdError;
  final void Function(int time, String adUnitId)? onAdImpression;
  final void Function(int time, String adUnitId, LoadAdError error)? onAdFailedToLoad;
  final Widget Function(double? width, double? height) placeHolder;

  @override
  State<GoodBannerAdaptiveAnchored> createState() => _GoodBannerAdaptiveAnchoredState();
}

class _GoodBannerAdaptiveAnchoredState extends State<GoodBannerAdaptiveAnchored> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? size;
  AdSize? defaultBannerSize;
  String? adUnitId;
  late Orientation _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentOrientation = MediaQuery.of(context).orientation;
    computeDefaultBannerSize();
    if (widget.adUnitId != null) {
      adUnitId = widget.adUnitId!;
      _loadAd();
    } else {
      _hideAd();
    }
  }

  @override
  void didUpdateWidget(covariant GoodBannerAdaptiveAnchored oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.adUnitId != null) {
        adUnitId = widget.adUnitId!;
        _loadAd();
      } else {
        _hideAd();
      }
    });
  }

  void computeDefaultBannerSize() {
    final width = MediaQuery.of(context).size.width;
    final height = width * 0.1557;
    defaultBannerSize = AdSize(width: width.toInt(), height: height.toInt());
    setState(() {});
  }

  void _hideAd() {
    setState(() {
      _isLoaded = false;
    });
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    try {
      // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate());

      if (size == null) {
        printDebug('Unable to get height of anchored banner. use default');
        size = defaultBannerSize;
      }

      if (widget.adUnitId == null) {
        return;
      }

      await _bannerAd?.dispose();
      if (!mounted) return;

      _bannerAd = BannerAd(
        adUnitId: adUnitId!,
        size: size!,
        request: widget.adRequest,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            printDebug('onAdLoaded($adUnitId): ${ad.responseInfo}');
            setState(() {
              // When the ad is loaded, get the ad size and use it to set
              // the height of the ad container.
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            printDebug('onAdFailedToLoad($adUnitId): $error');
            widget.onAdFailedToLoad
                ?.call(DateTime.now().toUtc().millisecondsSinceEpoch, ad.adUnitId, error);
            ad.dispose();
          },
          onAdImpression: (Ad ad) {
            printDebug('onAdImpression($adUnitId): ${ad.responseInfo}');
            widget.onAdImpression?.call(DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId!);
          },
        ),
      );
      await _bannerAd!.load();
    } catch (e, s) {
      printError('loadAd', e, s);
      widget.onLoadAdError?.call(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_currentOrientation == orientation && _bannerAd != null && _isLoaded) {
          return SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }
        // Reload the ad if the orientation changes.
        if (_currentOrientation != orientation) {
          _currentOrientation = orientation;
          _loadAd();
        }
        return widget.placeHolder(
          defaultBannerSize?.width.toDouble(),
          defaultBannerSize?.height.toDouble(),
        );
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
