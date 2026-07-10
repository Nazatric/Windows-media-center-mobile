import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A tiny, testable wrapper around [SharedPreferences]. Every read/write in
/// the app goes through here so there is exactly one place that knows about
/// key names and JSON encoding.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static StorageService? _instance;

  static Future<StorageService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Map<String, dynamic> getJsonMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> setJsonMap(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, jsonEncode(value));
  }
}
