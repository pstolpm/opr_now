import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/poi.dart';
import '../models/user_position.dart';
import '../repositories/poi_repository.dart';
import '../services/location_controller.dart';
import '../services/location_source.dart';
import '../utils/constants.dart';
import '../utils/demo_locations.dart';
import 'poi_detail_screen.dart';

/// Zentrale Kartenansicht der App.
///
/// Phase 2: MapLibre-Karte, zentriert auf den Landkreis OPR.
/// Phase 3: eigener Standort (GPS oder Demo) als GeoJSON-Layer,
///          Moduswechsel, Fehlermeldungen.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.locationController});

  final LocationController locationController;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- MapLibre-IDs für Quelle und Layer des Nutzerstandorts -------------
  static const _userSourceId = 'user-location';
  static const _userHaloLayerId = 'user-location-halo';
  static const _userDotLayerId = 'user-location-dot';

  // --- MapLibre-IDs für Quelle und Layer der Test-POIs (Phase 4) ---------
  static const _poiSourceId = 'test-pois';
  static const _poiLayerId = 'test-poi-dots';

  final _poiRepository = const PoiRepository();

  /// Geladene Test-POIs, nach id indiziert, damit ein Tap auf die Karte
  /// (liefert nur die id) den passenden [Poi] wiederfindet.
  Map<String, Poi> _poiById = {};

  /// Controller zum Steuern der Karte (Kamera, Layer). Wird von
  /// MapLibre nach dem Erzeugen der nativen Kartenansicht geliefert.
  MapLibreMapController? _map;

  /// true, sobald der Kartenstil (inkl. erster Kacheln) geladen ist.
  bool _styleLoaded = false;

  /// true, wenn der Stil nach einer Wartezeit noch nicht geladen ist -
  /// dann fehlt vermutlich die Internetverbindung.
  bool _loadTimedOut = false;

  Timer? _loadTimer;

  /// Kennung der Quelle, auf die zuletzt zentriert wurde (z. B. `gps`
  /// oder `demo:neuruppin`). Damit springt die Karte beim ersten Fix
  /// einer Quelle automatisch dorthin, aber nicht bei jedem weiteren
  /// Positions-Update derselben Quelle. Ändert sich die Quelle (Moduswechsel
  /// GPS/Demo oder Wechsel des Demo-Standorts), wird erneut zentriert.
  String? _lastCenteredKey;

  /// Letzter angezeigter Fehler, um denselben Fehler nicht mehrfach als
  /// SnackBar zu zeigen.
  LocationFailure? _lastShownFailure;

  LocationController get _location => widget.locationController;

  @override
  void initState() {
    super.initState();
    // Einfache Fehlerbehandlung: MapLibre meldet fehlgeschlagene
    // Stil-Downloads nicht direkt an Flutter. Deshalb ein Zeitlimit.
    _loadTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_styleLoaded) {
        setState(() => _loadTimedOut = true);
      }
    });
    _location.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _location.removeListener(_onLocationChanged);
    _map?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  // --- MapLibre-Callbacks --------------------------------------------------

  void _onMapCreated(MapLibreMapController controller) {
    _map = controller;
    _map!.onFeatureTapped.add(_onFeatureTapped);
  }

  Future<void> _onStyleLoaded() async {
    _loadTimer?.cancel();
    await _addUserLocationLayers();
    await _loadAndShowPois();
    if (!mounted) return;
    setState(() {
      _styleLoaded = true;
      _loadTimedOut = false;
    });
    // Falls schon eine Position vorliegt, sofort anzeigen.
    _onLocationChanged();
  }

  /// Legt GeoJSON-Quelle und zwei Circle-Layer für den Nutzerstandort an.
  ///
  /// Die Farbe wird datengetrieben aus dem Feature-Attribut `source`
  /// abgeleitet (MapLibre-Expression): Demo = orange, GPS = blau. So ist
  /// auf der Karte jederzeit erkennbar, ob simuliert wird.
  Future<void> _addUserLocationLayers() async {
    final map = _map;
    if (map == null) return;

    await map.addSource(
      _userSourceId,
      const GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    const colorBySource = [
      'match',
      ['get', 'source'],
      'demo',
      '#FB8C00', // orange
      '#1E88E5', // blau
    ];

    await map.addCircleLayer(
      _userSourceId,
      _userHaloLayerId,
      const CircleLayerProperties(
        circleRadius: 16,
        circleColor: colorBySource,
        circleOpacity: 0.25,
      ),
    );
    await map.addCircleLayer(
      _userSourceId,
      _userDotLayerId,
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: colorBySource,
        circleStrokeWidth: 2.5,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  // --- Test-POIs (Phase 4) --------------------------------------------------

  /// Lädt die lokalen Test-POIs (assets/data/test_pois.geojson) und zeigt
  /// sie als eigenen GeoJSON-Layer auf der Karte an. Ab Phase 5 treten
  /// weitere Quellen hinzu (PROJECT_BRAIN Abschnitt 11).
  Future<void> _loadAndShowPois() async {
    final map = _map;
    if (map == null) return;

    final pois = await _poiRepository.loadTestPois();
    if (!mounted) return;
    _poiById = {for (final poi in pois) poi.id: poi};

    await map.addSource(
      _poiSourceId,
      GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [for (final poi in pois) _poiToGeoJsonFeature(poi)],
        },
      ),
    );

    // Farbe je Kategorie (MapLibre-Expression, PROJECT_BRAIN Abschnitt 34/
    // "genaue UI-Gestaltung" ist offen, siehe Abschnitt 48 – vorläufige,
    // klar unterscheidbare Testfarben).
    const colorByCategory = [
      'match',
      ['get', 'category'],
      'sehenswuerdigkeit', '#8E24AA', // lila
      'natur', '#43A047', // grün
      'badestelle', '#039BE5', // hellblau
      'gastronomie', '#F4511E', // orange-rot
      '#757575', // Fallback: grau
    ];

    await map.addCircleLayer(
      _poiSourceId,
      _poiLayerId,
      const CircleLayerProperties(
        circleRadius: 8,
        circleColor: colorByCategory,
        circleStrokeWidth: 1.5,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  Map<String, dynamic> _poiToGeoJsonFeature(Poi poi) {
    return {
      'type': 'Feature',
      'id': poi.id,
      'properties': {'category': poi.category},
      // GeoJSON-Koordinatenreihenfolge: [longitude, latitude].
      'geometry': {
        'type': 'Point',
        'coordinates': [poi.longitude, poi.latitude],
      },
    };
  }

  /// Reagiert auf einen Tap auf eine Karten-Feature (POI-Layer) und öffnet
  /// die Detailansicht des zugehörigen POI.
  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    if (layerId != _poiLayerId) return;
    final poi = _poiById[id];
    if (poi == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoiDetailScreen(poi: poi)),
    );
  }

  // --- Standort-Änderungen -------------------------------------------------

  /// Wird bei jeder Änderung im [LocationController] aufgerufen.
  void _onLocationChanged() {
    if (!mounted) return;
    setState(() {}); // Banner / Busy-Anzeige aktualisieren
    _updateUserLocationOnMap();
    _showFailureIfNew();
  }

  Future<void> _updateUserLocationOnMap() async {
    final map = _map;
    if (map == null || !_styleLoaded) return;

    final position = _location.position;
    final features = <Map<String, dynamic>>[
      if (position != null) position.toGeoJsonFeature(),
    ];
    await map.setGeoJsonSource(_userSourceId, {
      'type': 'FeatureCollection',
      'features': features,
    });

    final currentKey =
        _location.isDemo ? 'demo:${_location.demoLocation.id}' : 'gps';
    if (position != null && currentKey != _lastCenteredKey) {
      _lastCenteredKey = currentKey;
      await _centerOn(position, zoom: 13);
    }
  }

  Future<void> _centerOn(UserPosition position, {double zoom = 14}) async {
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        zoom,
      ),
    );
  }

  void _showFailureIfNew() {
    final failure = _location.failure;
    if (failure == null) {
      _lastShownFailure = null;
      return;
    }
    if (failure == _lastShownFailure) return;
    _lastShownFailure = failure;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(_buildFailureSnackBar(failure));
  }

  /// Verständliche Meldung je Fehlerfall, wo sinnvoll mit Aktion.
  SnackBar _buildFailureSnackBar(LocationFailure failure) {
    switch (failure) {
      case LocationFailure.serviceDisabled:
        return SnackBar(
          content: const Text('Standortdienste sind ausgeschaltet.'),
          action: SnackBarAction(
            label: 'Einstellungen',
            onPressed: _location.openLocationSettings,
          ),
          duration: const Duration(seconds: 8),
        );
      case LocationFailure.permissionDenied:
        return SnackBar(
          content: const Text('Standortberechtigung wurde verweigert.'),
          action: SnackBarAction(
            label: 'Erneut fragen',
            onPressed: _location.startTracking,
          ),
          duration: const Duration(seconds: 8),
        );
      case LocationFailure.permissionDeniedForever:
        return SnackBar(
          content: const Text(
            'Standortberechtigung dauerhaft verweigert. '
            'Bitte in den App-Einstellungen erlauben oder Demo-Modus nutzen.',
          ),
          action: SnackBarAction(
            label: 'App-Einstellungen',
            onPressed: _location.openAppSettings,
          ),
          duration: const Duration(seconds: 10),
        );
      case LocationFailure.timeout:
        return const SnackBar(
          content: Text('Keine Position erhalten (Zeitlimit). Bitte erneut versuchen.'),
        );
      case LocationFailure.unknown:
        return const SnackBar(
          content: Text('Standort konnte nicht ermittelt werden.'),
        );
    }
  }

  // --- Aktionen ------------------------------------------------------------

  /// Kamera zurück auf den gesamten Landkreis setzen.
  Future<void> _showWholeDistrict() async {
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapConstants.oprBounds,
        left: 24,
        top: 24,
        right: 24,
        bottom: 24,
      ),
    );
  }

  /// Einmalig orten und auf die Position zentrieren.
  Future<void> _locateMe() async {
    final position = await _location.locateOnce();
    if (position != null) {
      await _centerOn(position);
    }
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPR NOW'),
        actions: [_buildModeMenu()],
      ),
      body: Column(
        children: [
          if (_location.isDemo) _DemoBanner(name: _location.demoLocation.name),
          Expanded(
            child: Stack(
              children: [
                MapLibreMap(
                  styleString: MapConstants.styleUrl,
                  initialCameraPosition: const CameraPosition(
                    target: MapConstants.oprCenter,
                    zoom: MapConstants.initialZoom,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  // Eigener Standort wird als GeoJSON-Layer gezeichnet
                  // (funktioniert auch im Demo-Modus), daher aus.
                  myLocationEnabled: false,
                  // Dreh- und Neigegesten für den MVP deaktivieren:
                  // vereinfacht die Bedienung, "Norden oben" bleibt.
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
                if (!_styleLoaded)
                  Center(
                    child: _loadTimedOut
                        ? const _MapLoadHint()
                        : const CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab-district',
            onPressed: _showWholeDistrict,
            tooltip: 'Gesamten Landkreis anzeigen',
            child: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab-locate',
            onPressed: _location.busy ? null : _locateMe,
            tooltip: 'Auf meinen Standort zentrieren',
            child: _location.busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  /// Menü zum Umschalten zwischen echtem GPS und Demo-Standorten.
  Widget _buildModeMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Standortmodus',
      icon: Icon(_location.isDemo ? Icons.science : Icons.gps_fixed),
      onSelected: (value) {
        if (value == 'gps') {
          _location.setMode(LocationMode.gps);
        } else {
          final demo = demoLocations.firstWhere((d) => d.id == value);
          _location.selectDemoLocation(demo);
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'gps',
          checked: !_location.isDemo,
          child: const Text('Echtes GPS'),
        ),
        const PopupMenuDivider(),
        for (final demo in demoLocations)
          CheckedPopupMenuItem(
            value: demo.id,
            checked: _location.isDemo && _location.demoLocation.id == demo.id,
            child: Text('Demo – ${demo.name}'),
          ),
      ],
    );
  }
}

/// Deutlich sichtbarer Hinweis, dass der Standort simuliert wird
/// (PROJECT_BRAIN Abschnitt 26: Demo-Modus klar kennzeichnen).
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade700,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.science, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Demo-Standort: $name (simuliert)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hinweis, wenn die Karte nicht innerhalb des Zeitlimits geladen wurde.
class _MapLoadHint extends StatelessWidget {
  const _MapLoadHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 8),
            Text(
              'Karte konnte nicht geladen werden.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Bitte Internetverbindung prüfen. Die Kartenkacheln '
              'werden von OpenFreeMap geladen.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
