// Unit-Tests für die Karten-Konstanten.
//
// Die native MapLibre-Ansicht selbst kann in Flutter-Tests nicht gerendert
// werden (Platform View ohne Android-Laufzeit). Die Karte wird deshalb
// manuell im Emulator getestet (siehe PROJECT_BRAIN Abschnitt 38).
// Hier wird geprüft, dass die räumlichen Konstanten in sich stimmig sind.

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:opr_now/utils/constants.dart';

/// Hilfsfunktion: Liegt [point] innerhalb von [bounds] (WGS84)?
bool _contains(LatLngBounds bounds, LatLng point) {
  return point.latitude >= bounds.southwest.latitude &&
      point.latitude <= bounds.northeast.latitude &&
      point.longitude >= bounds.southwest.longitude &&
      point.longitude <= bounds.northeast.longitude;
}

void main() {
  group('MapConstants', () {
    test('Bounding Box ist korrekt orientiert (SW < NE)', () {
      final b = MapConstants.oprBounds;
      expect(b.southwest.latitude, lessThan(b.northeast.latitude));
      expect(b.southwest.longitude, lessThan(b.northeast.longitude));
    });

    test('Kartenmitte liegt innerhalb der OPR-Bounding-Box', () {
      expect(_contains(MapConstants.oprBounds, MapConstants.oprCenter), isTrue);
    });

    test('Wichtige Orte des Landkreises liegen in der Bounding Box', () {
      const neuruppin = LatLng(52.9226, 12.8030);
      const rheinsberg = LatLng(53.0986, 12.8967);
      const kyritz = LatLng(52.9432, 12.3966);
      const wittstock = LatLng(53.1636, 12.4855);

      for (final ort in [neuruppin, rheinsberg, kyritz, wittstock]) {
        expect(_contains(MapConstants.oprBounds, ort), isTrue,
            reason: '$ort sollte innerhalb der OPR-Bounds liegen');
      }
    });

    test('Stil-URL ist eine gültige HTTPS-Adresse', () {
      final uri = Uri.parse(MapConstants.styleUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });
  });
}
