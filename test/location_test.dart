// Unit-Tests für Standort-Modell, Demo-Quelle und LocationController.
//
// Die GPS-Quelle selbst (geolocator) lässt sich nur auf einem Gerät
// testen; hier wird die Logik um sie herum geprüft.

import 'package:flutter_test/flutter_test.dart';

import 'package:opr_now/models/user_position.dart';
import 'package:opr_now/services/location_controller.dart';
import 'package:opr_now/services/location_source.dart';
import 'package:opr_now/utils/demo_locations.dart';

void main() {
  group('UserPosition', () {
    test('GeoJSON-Feature hat Koordinaten in der Reihenfolge [lon, lat]', () {
      final p = UserPosition(
        latitude: 52.9265,
        longitude: 12.8033,
        timestamp: DateTime(2026, 9, 17),
        source: PositionSource.demo,
      );
      final feature = p.toGeoJsonFeature();
      final coords = (feature['geometry'] as Map)['coordinates'] as List;

      expect(feature['type'], 'Feature');
      expect(coords, [12.8033, 52.9265]);
      expect((feature['properties'] as Map)['source'], 'demo');
    });
  });

  group('DemoLocationSource', () {
    test('liefert den Startpunkt und danach Verschiebungen', () async {
      final source = DemoLocationSource(demoLocations.first);
      final received = <UserPosition>[];
      final sub = source.positionStream().listen(received.add);

      await Future<void>.delayed(Duration.zero);
      source.moveTo(53.0, 12.9);
      await Future<void>.delayed(Duration.zero);

      expect(received.length, 2);
      expect(received.first.latitude, demoLocations.first.latitude);
      expect(received.last.latitude, 53.0);
      expect(received.every((p) => p.isDemo), isTrue);

      await sub.cancel();
      source.dispose();
    });
  });

  group('LocationController', () {
    test('startet im GPS-Modus, wechselt in den Demo-Modus mit Position', () async {
      final controller = LocationController(gpsSource: GpsLocationSource());
      expect(controller.mode, LocationMode.gps);
      expect(controller.position, isNull);

      await controller.selectDemoLocation(demoLocations.last);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isDemo, isTrue);
      expect(controller.demoLocation.id, demoLocations.last.id);
      expect(controller.position, isNotNull);
      expect(controller.position!.latitude, demoLocations.last.latitude);
      expect(controller.failure, isNull);

      controller.dispose();
    });

    test('benachrichtigt Listener bei Moduswechsel', () async {
      final controller = LocationController(gpsSource: GpsLocationSource());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.selectDemoLocation(demoLocations.first);
      await Future<void>.delayed(Duration.zero);

      expect(notifications, greaterThan(0));
      controller.dispose();
    });
  });
}
