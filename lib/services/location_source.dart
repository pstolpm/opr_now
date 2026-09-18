import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/user_position.dart';
import '../utils/demo_locations.dart';

/// Gründe, warum keine Position ermittelt werden konnte.
enum LocationFailure {
  /// Standortdienste des Geräts sind ausgeschaltet.
  serviceDisabled,

  /// Nutzer hat die Berechtigung (für dieses Mal) verweigert.
  permissionDenied,

  /// Nutzer hat die Berechtigung dauerhaft verweigert - die App kann sie
  /// nicht mehr selbst anfragen, nur die System-Einstellungen öffnen.
  permissionDeniedForever,

  /// Innerhalb des Zeitlimits kam keine Position.
  timeout,

  unknown,
}

class LocationException implements Exception {
  const LocationException(this.failure, [this.details]);

  final LocationFailure failure;
  final String? details;

  @override
  String toString() => 'LocationException(${failure.name}${details == null ? '' : ': $details'})';
}

/// Gemeinsame Schnittstelle für Positionsquellen.
///
/// Die App arbeitet nur gegen dieses Interface. Ob die Position vom
/// echten GPS ([GpsLocationSource]) oder aus dem Demo-Modus
/// ([DemoLocationSource]) stammt, ist für Karte, Context Engine und
/// Geofence unerheblich.
abstract class LocationSource {
  /// Einmalig die aktuelle Position ermitteln.
  ///
  /// Wirft [LocationException], wenn keine Position möglich ist.
  Future<UserPosition> getCurrentPosition();

  /// Fortlaufende Positionsupdates.
  Stream<UserPosition> positionStream();

  /// Ressourcen freigeben.
  void dispose() {}
}

/// Echte Gerätepositionen über das Package `geolocator`.
class GpsLocationSource implements LocationSource {
  GpsLocationSource({
    this.settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      // Erst ab 10 m Bewegung ein neues Update - spart Akku und
      // verhindert Marker-Zittern.
      distanceFilter: 10,
    ),
    this.timeLimit = const Duration(seconds: 20),
  });

  final LocationSettings settings;
  final Duration timeLimit;

  /// Prüft Standortdienst und Berechtigung; fragt die Berechtigung bei
  /// Bedarf an. Wirft [LocationException], wenn Ortung nicht möglich ist.
  Future<void> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationFailure.permissionDenied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationFailure.permissionDeniedForever);
      case LocationPermission.unableToDetermine:
        throw const LocationException(LocationFailure.unknown, 'permission unableToDetermine');
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return;
    }
  }

  @override
  Future<UserPosition> getCurrentPosition() async {
    await ensureReady();
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(timeLimit);
      return _toUserPosition(position);
    } on TimeoutException {
      throw const LocationException(LocationFailure.timeout);
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException(LocationFailure.unknown, e.toString());
    }
  }

  @override
  Stream<UserPosition> positionStream() async* {
    await ensureReady();
    yield* Geolocator.getPositionStream(locationSettings: settings)
        .map(_toUserPosition);
  }

  /// Öffnet die Standort-Einstellungen des Systems (Dienst aktivieren).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Öffnet die App-Einstellungen (Berechtigung nach "dauerhaft
  /// verweigert" wieder erteilen).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  UserPosition _toUserPosition(Position p) {
    return UserPosition(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      timestamp: p.timestamp,
      source: PositionSource.gps,
    );
  }

  @override
  void dispose() {}
}

/// Simulierte Position für den Demo-Modus.
///
/// Liefert einen festen Punkt, der über [moveTo] verschoben werden kann
/// (z. B. später, um das Erreichen eines Ziels vorzuführen).
class DemoLocationSource implements LocationSource {
  DemoLocationSource(DemoLocation start)
      : _current = _fromDemoLocation(start);

  UserPosition _current;
  final _controller = StreamController<UserPosition>.broadcast();

  UserPosition get current => _current;

  /// Auf einen vorbelegten Demo-Standort wechseln.
  void setLocation(DemoLocation location) {
    _emit(_fromDemoLocation(location));
  }

  /// Auf beliebige Koordinaten verschieben.
  void moveTo(double latitude, double longitude) {
    _emit(UserPosition(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: 5,
      timestamp: DateTime.now(),
      source: PositionSource.demo,
    ));
  }

  void _emit(UserPosition position) {
    _current = position;
    if (!_controller.isClosed) _controller.add(position);
  }

  @override
  Future<UserPosition> getCurrentPosition() async => _current;

  @override
  Stream<UserPosition> positionStream() async* {
    // Erst den aktuellen Stand liefern, danach alle Änderungen.
    yield _current;
    yield* _controller.stream;
  }

  @override
  void dispose() {
    _controller.close();
  }

  static UserPosition _fromDemoLocation(DemoLocation l) {
    return UserPosition(
      latitude: l.latitude,
      longitude: l.longitude,
      accuracyMeters: 5,
      timestamp: DateTime.now(),
      source: PositionSource.demo,
    );
  }
}
