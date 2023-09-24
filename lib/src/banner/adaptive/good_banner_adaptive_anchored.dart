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
    this.adsPlaceholderColor,
    this.onLoadAdError,
    this.onAdImpression,
  }) : super(key: key);

  final String? adUnitId;
  final AdRequest adRequest;
  final int interval;
  final Color? adsPlaceholderColor;
  final void Function(Object, StackTrace)? onLoadAdError;
  final void Function(int time, String adUnitId)? onAdImpression;

  @override
  State<GoodBannerAdaptiveAnchored> createState() =>
      _GoodBannerAdaptiveAnchoredState();
}

class _GoodBannerAdaptiveAnchoredState
    extends State<GoodBannerAdaptiveAnchored> {
  BannerAd? _anchoredAdaptiveAd;
  bool _isLoaded = false;
  AnchoredAdaptiveBannerAdSize? size;
  Size? defaultBannerSize;
  String? adUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    computeDefaultBannerSize();
    if (widget.adUnitId != null) {
      adUnitId = widget.adUnitId!;
      _initAd();
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
        _initAd();
      } else {
        _hideAd();
      }
    });
  }

  void computeDefaultBannerSize() {
    final width = MediaQuery.of(context).size.width;
    final height = width * 0.1557;
    setState(() {
      defaultBannerSize = Size(width, height);
    });
  }

  void _hideAd() {
    setState(() {
      _anchoredAdaptiveAd = null;
      _isLoaded = false;
    });
  }

  Future<void> _initAd() async {
    final lastImpressions = await getLastImpressions(adUnitId!);
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
    try {
      // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
      size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate());

      if (size == null) {
        printDebug('Unable to get height of anchored banner.');
        return;
      }

      setState(() {});

      if (widget.adUnitId == null) {
        return;
      }

      _anchoredAdaptiveAd = BannerAd(
        adUnitId: adUnitId!,
        size: size!,
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
            printDebug('impression: ${ad.responseInfo}');
            widget.onAdImpression?.call(
                DateTime.now().toUtc().millisecondsSinceEpoch, adUnitId!);
          },
        ),
      );
      await setLastImpressions(
          adUnitId!, DateTime.now().millisecondsSinceEpoch);
      return _anchoredAdaptiveAd!.load();
    } catch (e, s) {
      printError('loadAd', e, s);
      widget.onLoadAdError?.call(e, s);
    }
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
      return SizedBox(
        width: defaultBannerSize?.width.toDouble(),
        height: defaultBannerSize?.height.toDouble(),
        child: Center(
          child: Text(
            'Ads placeholder',
            style: TextStyle(color: widget.adsPlaceholderColor),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _anchoredAdaptiveAd?.dispose();
  }
}
