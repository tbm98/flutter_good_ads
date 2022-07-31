# good_flutter_ads

## Features

* Banner
  * Auto config and load for you
  * Load safety with interval

* Interstitial
  * Load and show safety with interval 


## Getting started (see more in example)


### Import
```
flutter pub add flutter_good_ads
```
and
```dart
import 'package:flutter_good_ads/flutter_good_ads.dart';
```

### Config main function like this
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(MyApp());
}
```

## Usage

### Banner

Put this block everywhere you want

```dart
GoodBanner(
  adUnitId: 'ca-app-pub-3940256099942544/6300978111',
  adRequest: AdRequest(),
  interval: 60000,
  adSize: AdSize.banner,
)
```

### Interstitial

1. Declare a GoodInterstitial
```dart
  final interstitialAd = const GoodInterstitial(
    adUnitId: 'ca-app-pub-3940256099942544/8691691433',
    adRequest: AdRequest(),
    interval: 60000,
  );
```

2. Call load() at somewhere (ex: initState)
```dart
  @override
  void initState() {
    super.initState();
    interstitialAd.load();
  }
```

3. Call show() when you want
```dart
  if (_counter % 5 == 0) {
    interstitialAd.show(reloadAfterShow: true);
  }
```