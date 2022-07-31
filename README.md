TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

- Banner
-- Auto config and load for you
-- Load safety with interval
- Interstitial
-- Load and safety with interval 


## Getting started

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

-- Declare a GoodInterstitial
```dart
  final interstitialAd = const GoodInterstitial(
    adUnitId: 'ca-app-pub-3940256099942544/8691691433',
    adRequest: AdRequest(),
    interval: 60000,
  );
```

-- Call load() at somewhere (ex: initState)
```dart
  @override
  void initState() {
    super.initState();
    interstitialAd.load();
  }
```

-- Call show() when you want
```dart
  if (_counter % 5 == 0) {
    interstitialAd.show(reloadAfterShow: true);
  }
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
