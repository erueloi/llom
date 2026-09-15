import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveïdor de configuració i accessibilitat per a Llom (UI Sènior)
class SettingsProvider extends ChangeNotifier {
  static const String extraLargeTextKey = 'extra_large_text';

  final SharedPreferences? _prefsInstance;
  bool _isExtraLargeText = false;
  bool _isInitialized = false;

  SettingsProvider({SharedPreferences? prefs}) : _prefsInstance = prefs {
    _loadPreferences();
  }

  bool get isExtraLargeText => _isExtraLargeText;
  bool get isInitialized => _isInitialized;

  /// Factor d'escala de text: 1.25 per a text extra gran, 1.0 per a escala estàndard
  double get textScaleFactor => _isExtraLargeText ? 1.25 : 1.0;

  Future<void> _loadPreferences() async {
    try {
      final prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      _isExtraLargeText = prefs.getBool(extraLargeTextKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
    }
  }

  /// Activa o desactiva el mode de text extra gran i el desa a SharedPreferences
  Future<void> setExtraLargeText(bool value) async {
    if (_isExtraLargeText == value) return;
    _isExtraLargeText = value;
    notifyListeners();

    try {
      final prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setBool(extraLargeTextKey, value);
    } catch (_) {
      // Ignorem errors de persistència per no bloquejar la interfície
    }
  }
}
