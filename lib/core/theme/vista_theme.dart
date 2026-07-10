import 'package:flutter/widgets.dart';

/// The four theme variants requested: Blue / Green / Silver / Dark Vista.
enum VistaVariant { blue, green, silver, dark }

/// A single, self-contained palette. Every screen pulls its colors from
/// here rather than hard-coding hex values, so switching variants in
/// Settings instantly re-skins the whole app.
class VistaPalette {
  final String label;
  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color glassTint;
  final Color glassBorder;
  final Color accentGlow;
  final Color textPrimary;
  final Color textSecondary;

  const VistaPalette({
    required this.label,
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.glassTint,
    required this.glassBorder,
    required this.accentGlow,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const Map<VistaVariant, VistaPalette> all = {
    VistaVariant.blue: VistaPalette(
      label: 'Blue Vista',
      skyTop: Color(0xFF3A7BD5),
      skyMid: Color(0xFF0F3C6E),
      skyBottom: Color(0xFF020B18),
      glassTint: Color(0x339FD8FF),
      glassBorder: Color(0x66CFEBFF),
      accentGlow: Color(0xFF6FC3FF),
      textPrimary: Color(0xFFF3F9FF),
      textSecondary: Color(0xFFAFCBEA),
    ),
    VistaVariant.green: VistaPalette(
      label: 'Green Vista',
      skyTop: Color(0xFF4CA35A),
      skyMid: Color(0xFF0F4A24),
      skyBottom: Color(0xFF03130A),
      glassTint: Color(0x33B9FFCB),
      glassBorder: Color(0x66D6FFE3),
      accentGlow: Color(0xFF7CFFA0),
      textPrimary: Color(0xFFF2FFF5),
      textSecondary: Color(0xFFB9E7C4),
    ),
    VistaVariant.silver: VistaPalette(
      label: 'Silver Vista',
      skyTop: Color(0xFF9AA7B0),
      skyMid: Color(0xFF48525A),
      skyBottom: Color(0xFF0C0E10),
      glassTint: Color(0x33E7EEF2),
      glassBorder: Color(0x66F3F7FA),
      accentGlow: Color(0xFFDCEBF5),
      textPrimary: Color(0xFFF8FAFB),
      textSecondary: Color(0xFFC7D1D8),
    ),
    VistaVariant.dark: VistaPalette(
      label: 'Dark Vista',
      skyTop: Color(0xFF1B2733),
      skyMid: Color(0xFF0A0F16),
      skyBottom: Color(0xFF000000),
      glassTint: Color(0x33668099),
      glassBorder: Color(0x554E6B85),
      accentGlow: Color(0xFF3F6E94),
      textPrimary: Color(0xFFE7EEF5),
      textSecondary: Color(0xFF8FA3B5),
    ),
  };
}
