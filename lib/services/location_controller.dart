import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_position.dart';
import '../utils/demo_locations.dart';
import 'location_source.dart';

/// Standortmodus der App (PROJECT_BRAIN Abschnitt 26).
enum LocationMode { gps, demo }

/// Hält den aktuellen Standortzustand der App und verteilt Änderungen an
/// die UI.
///
/// Verwendet Flutters eingebautes [ChangeNotifier]: Widgets hören per
/// `ListenableBuilder` zu und bauen sich bei `notifyListeners()` neu.
/// Damit kommen wir ohne zusätzliches State-Management-Package aus.
class LocationController extends ChangeNotifier {
  LocationController({
    required GpsLocationSource gpsSource,
    LocationMode initialMode = LocationMode.gps,
    DemoLocation? initialDemoLocation,
  })  : _gps = gpsSource,
        _mode = initialMode,
        _demoLocation = initialDemoLocation ?? demoLocations.first {
    _demo = DemoLocationSource(_demoLocation);
  }

  final GpsLocationSource _gps;
  late final DemoLocationSource _demo;

  LocationMode _mode;
  DemoLocation _demoLocation;
  UserPosition? _position;
  LocationFailure? _failure;
  bool _busy = false;
  StreamSubscription<UserPosition>? _subscription;

  LocationMode get mode => _mode;
  bool get isDemo => _mode == LocationMode.demo;
  DemoLocation get demoLocation => _demoLocation;

  /// Letzte bekannte Position (GPS oder Demo), null solange keine vorliegt.
  UserPosition? get position => _position;

  /// Letzter Fehler, null wenn alles in Ordnung ist.
  LocationFailure? get failure => _failure;

  /// true, während eine Position ermittelt wird.
  bool get busy => _busy;

  /// Aktive Quelle je nach Modus.
  LocationSource get _source => isDemo ? _demo : _gps;

  /// Positionsupdates der aktiven Quelle abonnieren.
  ///
  /// Bei Fehlern (Dienst aus, Berechtigung verweigert, ...) wird [failure]
  /// gesetzt; die App bleibt benutzbar.
  Future<void> startTracking() async {
    await _subscription?.cancel();
    _setBusy(true);
    _failure = null;

    _subscription = _source.positionStream().listen(
      (p) {
        _position = p;
        _setBusy(false);
      },
      onError: (Object e) {
        _failure = e is LocationException ? e.failure : LocationFailure.unknown;
        _setBusy(false);
      },
    );
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Einmalig neu orten (z. B. Button "Auf meinen Standort").
  Future<UserPosition?> locateOnce() async {
    _setBusy(true);
    _failure = null;
    try {
      _position = await _source.getCurrentPosition();
      return _position;
    } on LocationException catch (e) {
      _failure = e.failure;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Zwischen echtem GPS und Demo-Modus wechseln.
  Future<void> setMode(LocationMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _position = null;
    _failure = null;
    notifyListeners();
    await startTracking();
  }

  /// Demo-Standort wählen (schaltet automatisch in den Demo-Modus).
  Future<void> selectDemoLocation(DemoLocation location) async {
    _demoLocation = location;
    _demo.setLocation(location);
    if (_mode != LocationMode.demo) {
      await setMode(LocationMode.demo);
    } else {
      // _demo.setLocation() aktualisiert die interne Position sofort
      // (synchron), verschickt sie aber zusätzlich über einen Stream, der
      // seine Listener erst im nächsten Microtask benachrichtigt. Ohne diese
      // Zeile würde notifyListeners() unten die UI mit der noch alten
      // Position benachrichtigen (falsches Zentrieren auf der Karte), obwohl
      // demoLocation schon auf den neu gewählten Ort zeigt.
      _position = _demo.current;
      _failure = null;
      notifyListeners();
    }
  }

  /// Demo-Position frei verschieben (nur im Demo-Modus wirksam).
  void moveDemoPosition(double latitude, double longitude) {
    if (!isDemo) return;
    _demo.moveTo(latitude, longitude);
  }

  Future<bool> openLocationSettings() => _gps.openLocationSettings();
  Future<bool> openAppSettings() => _gps.openAppSettings();

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _demo.dispose();
    _gps.dispose();
    super.dispose();
  }
}
