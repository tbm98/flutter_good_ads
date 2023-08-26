import 'package:shared_preferences/shared_preferences.dart';

Future<bool> setLastImpressions(String adUnitId, int time) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setInt(adUnitId, time);
}

Future<int> getLastImpressions(String adUnitId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(adUnitId) ?? 0;
}
