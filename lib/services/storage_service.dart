import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyDisclaimerAccepted = 'cxr_disclaimer_accepted';
  static const String _keyServerUrl = 'cxr_server_url';
  static const String _keyOfflineMode = 'cxr_offline_mode';
  static const String defaultServerUrl = 'http://127.0.0.1:5000';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool isDisclaimerAccepted() {
    return _prefs.getBool(_keyDisclaimerAccepted) ?? false;
  }

  Future<void> setDisclaimerAccepted(bool accepted) async {
    await _prefs.setBool(_keyDisclaimerAccepted, accepted);
  }

  String getServerUrl() {
    return _prefs.getString(_keyServerUrl) ?? defaultServerUrl;
  }

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url.trim());
  }

  bool getOfflineDemoMode() {
    return _prefs.getBool(_keyOfflineMode) ?? false;
  }

  Future<void> setOfflineDemoMode(bool enabled) async {
    await _prefs.setBool(_keyOfflineMode, enabled);
  }
}

