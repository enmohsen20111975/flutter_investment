import 'package:flutter/material.dart';

class UIConstants {
  // Padding / margins
  static const double horizontalPadding = 16.0;
  static const double verticalPadding   = 12.0;
  static const double cardRadius       = 16.0;
  static const double elementSpacing   = 20.0;

  // Font sizes
  static const double headline = 24.0;
  static const double title    = 18.0;
  static const double body     = 14.0;
  static const double caption  = 12.0;

  // Chart height (30% of screen height)
  static double chartHeight(BuildContext ctx) =>
      MediaQuery.of(ctx).size.height * 0.30;
  
  // Standard elevation
  static const double elevation = 0.0;
  
  // Opacity for glassmorphism effects
  static const double surfaceOpacity = 0.8;
}
