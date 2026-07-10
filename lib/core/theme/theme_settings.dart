import 'package:flutter/foundation.dart';

import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../constants/app_constants.dart';
import 'vista_theme.dart';

/// Everything on the Settings screen lives here: theme variant, the four
/// "intensity" sliders, performance mode and developer mode. It is a single
/// [ChangeNotifier] provided at the root of the app so any widget can watch
/// it and instantly re-skin when the user changes something.
class ThemeSettings extends ChangeNotifier {
  ThemeSettings(this._storage) {
    _load();
  }

  final StorageService _storage;

  VistaVariant _variant = VistaVariant.blue;
  double _glassIntensity = 0.7;
  double _blurAmount = 0.6;
  double _glowIntensity = 0.7;
  double _animationSpeed = 1.0;
  double _particleDensity = 0.6;
  bool _performanceMode = false;
  bool _developerMode = false;
  bool _soundEffectsEnabled = true;

  VistaVariant get variant => _variant;
  VistaPalette get palette => VistaPalette.all[_variant]!;
  double get glassIntensity => _glassIntensity;
  double get blurAmount => _performanceMode ? _blurAmount * 0.35 : _blurAmount;
  double get glowIntensity => _glowIntensity;
  double get animationSpeed => _animationSpeed;
  double get particleDensity => _performanceMode ? _particleDensity * 0.3 : _particleDensity;
  bool get performanceMode => _performanceMode;
  bool get developerMode => _developerMode;
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  void _load() {
    final json = _storage.getJsonMap(AppConstants.prefThemeSettings);
    if (json.isEmpty) return;
    _variant = VistaVariant.values.firstWhere(
      (v) => v.name == json['variant'],
      orElse: () => VistaVariant.blue,
    );
    _glassIntensity = (json['glassIntensity'] as num?)?.toDouble() ?? _glassIntensity;
    _blurAmount = (json['blurAmount'] as num?)?.toDouble() ?? _blurAmount;
    _glowIntensity = (json['glowIntensity'] as num?)?.toDouble() ?? _glowIntensity;
    _animationSpeed = (json['animationSpeed'] as num?)?.toDouble() ?? _animationSpeed;
    _particleDensity = (json['particleDensity'] as num?)?.toDouble() ?? _particleDensity;
    _performanceMode = json['performanceMode'] as bool? ?? _performanceMode;
    _developerMode = json['developerMode'] as bool? ?? _developerMode;
    _soundEffectsEnabled = json['soundEffectsEnabled'] as bool? ?? _soundEffectsEnabled;
    SoundService.instance.muted = !_soundEffectsEnabled;
    notifyListeners();
  }

  Future<void> _persist() {
    return _storage.setJsonMap(AppConstants.prefThemeSettings, {
      'variant': _variant.name,
      'glassIntensity': _glassIntensity,
      'blurAmount': _blurAmount,
      'glowIntensity': _glowIntensity,
      'animationSpeed': _animationSpeed,
      'particleDensity': _particleDensity,
      'performanceMode': _performanceMode,
      'developerMode': _developerMode,
      'soundEffectsEnabled': _soundEffectsEnabled,
    });
  }

  void setVariant(VistaVariant v) {
    _variant = v;
    notifyListeners();
    _persist();
  }

  void setGlassIntensity(double v) {
    _glassIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
    _persist();
  }

  void setBlurAmount(double v) {
    _blurAmount = v.clamp(0.0, 1.0);
    notifyListeners();
    _persist();
  }

  void setGlowIntensity(double v) {
    _glowIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
    _persist();
  }

  void setAnimationSpeed(double v) {
    _animationSpeed = v.clamp(0.25, 2.0);
    notifyListeners();
    _persist();
  }

  void setParticleDensity(double v) {
    _particleDensity = v.clamp(0.0, 1.0);
    notifyListeners();
    _persist();
  }

  void setPerformanceMode(bool v) {
    _performanceMode = v;
    notifyListeners();
    _persist();
  }

  void setDeveloperMode(bool v) {
    _developerMode = v;
    notifyListeners();
    _persist();
  }

  void setSoundEffectsEnabled(bool v) {
    _soundEffectsEnabled = v;
    SoundService.instance.muted = !v;
    notifyListeners();
    _persist();
  }

  void resetToDefaults() {
    _variant = VistaVariant.blue;
    _glassIntensity = 0.7;
    _blurAmount = 0.6;
    _glowIntensity = 0.7;
    _animationSpeed = 1.0;
    _particleDensity = 0.6;
    _performanceMode = false;
    _developerMode = false;
    _soundEffectsEnabled = true;
    SoundService.instance.muted = false;
    notifyListeners();
    _persist();
  }
}
