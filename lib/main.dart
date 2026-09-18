import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'app/app.dart';

/// Einstiegspunkt der App.
///
/// Bewusst minimal gehalten: Die eigentliche App-Konfiguration
/// (Theme, Startbildschirm, Dienste) liegt in `app/app.dart`.
void main() {
  // Karte auf Android in eine TextureView rendern statt in eine
  // GLSurfaceView im "Virtual Display". Der Standardmodus baut die native
  // Kartenansicht bei jedem Pause/Resume der Activity (z. B. Android-
  // Berechtigungsdialog) neu auf und stürzte im Emulator ab.
  // Muss vor dem ersten MapLibreMap-Widget gesetzt werden.
  MapLibreMap.useHybridComposition = true;

  runApp(const OprNowApp());
}
