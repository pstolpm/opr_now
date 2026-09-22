import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/user_position.dart';

/// Einfacher, selbst implementierter Geofence auf Basis laufender
/// Standort-Updates (PROJECT_BRAIN Abschnitt 8, Phase 10).
///
/// Kein systemweites Background-Geofencing noetig (Abschnitt 8: "fuer den
/// MVP reicht eine selbst implementierte Distanzpruefung"). Die Klasse
/// merkt sich ein aktives Ziel und meldet einmalig, wenn die Distanz dazu
/// den Schwellenwert unterschreitet - nicht bei jedem weiteren
/// Standort-Update erneut (Abschnitt 38: "kein wiederholtes
/// Spam-Triggern").
class GeofenceLogic {
  GeofenceLogic({this.thresholdMeters = 75});

  /// Schwellenwert fuer "Ziel erreicht" (PROJECT_BRAIN Abschnitt 8,
  /// Beispielwert 75 m). War in Abschnitt 48 als offene Entscheidung
  /// vermerkt - mit Phase 10 auf 75 m festgelegt.
  final double thresholdMeters;

  LatLng? _target;
  bool _triggered = false;

  /// Aktiviert den Geofence fuer [target] (typischerweise das Ziel der
  /// zuletzt berechneten Route, siehe map_screen.dart). Bei einem neuen
  /// Ziel wird der "bereits ausgeloest"-Zustand zurueckgesetzt; beim
  /// gleichen Ziel bleibt er erhalten, damit ein Re-Zentrieren der Karte
  /// keinen erneuten Alarm ausloest.
  void setTarget(LatLng? target) {
    if (target != _target) {
      _target = target;
      _triggered = false;
    }
  }

  void clear() => setTarget(null);

  /// Prueft [position] gegen das aktive Ziel. Gibt genau beim Uebergang
  /// "ausserhalb -> innerhalb des Schwellenwerts" true zurueck (einmalig
  /// pro Ziel), sonst false.
  bool checkArrival(UserPosition position) {
    final target = _target;
    if (target == null || _triggered) return false;

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );

    if (distanceMeters <= thresholdMeters) {
      _triggered = true;
      return true;
    }
    return false;
  }
}
