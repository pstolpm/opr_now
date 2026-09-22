import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/poi.dart';
import '../models/user_position.dart';
import '../models/user_report.dart';
import '../models/weather_context.dart';
import '../logic/geofence_logic.dart';
import '../models/route_result.dart';
import '../repositories/poi_repository.dart';
import '../repositories/report_repository.dart';
import '../services/export_service.dart';
import '../services/location_controller.dart';
import '../services/location_source.dart';
import '../services/overpass_service.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';
import '../utils/demo_locations.dart';
import '../theme/app_theme.dart';
import '../widgets/legend_panel.dart';
import '../widgets/scale_bar.dart';
import '../widgets/zoom_control.dart';
import 'discover_screen.dart';
import '../models/tour_route_result.dart';
import 'info_screen.dart';
import 'poi_detail_screen.dart';
import 'report_screen.dart';

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
  final _bathingSiteRepository = const PoiRepository(
    assetPath: 'assets/data/bathing_sites_opr.geojson',
  );
  final _overtureRepository = const PoiRepository(
    assetPath: 'assets/data/overture_opr.geojson',
  );
  final _overpassService = OverpassService();

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

  // --- Wetter (Phase 5) -----------------------------------------------------
  final _weatherService = WeatherService();
  WeatherContext? _weather;
  bool _weatherLoading = false;
  WeatherFailure? _weatherFailure;

  // --- Routing (Phase 6) ------------------------------------------------
  static const _routeSourceId = 'route';
  static const _routeLayerId = 'route-line';
  bool _routeLayerAdded = false;
  final _geofence = GeofenceLogic();

  // --- Rundtour (vorgezogene Erweiterung, PROJECT_BRAIN Abschnitt 23) ----
  /// Verbleibende Ziele einer aktiven Rundtour (nach dem aktuellen
  /// Geofence-Ziel), in Besuchsreihenfolge - inkl. abschliessendem
  /// Rueckweg zum Start.
  final List<LatLng> _tourQueue = [];
  final List<String> _tourQueueLabels = [];

  /// Anzeigename des aktuell aktiven Geofence-Ziels (fuer die
  /// "X erreicht, weiter zu Y"-Meldung).
  String? _activeTourLabel;

  /// Ob gerade eine Rundtour laeuft (fuer die Abschlussmeldung).
  bool _tourActive = false;

  // --- Nutzer-Meldungen (Phase 8) -----------------------------------------
  static const _reportSourceId = 'user-reports';
  static const _reportLayerId = 'user-report-dots';
  bool _reportLayerAdded = false;
  final _reportRepository = ReportRepository();
  final _exportService = const ExportService();

  /// Geladene Meldungen, nach GeoJSON-Feature-id indiziert (Format
  /// `report:<sqlite-id>`), damit ein Tap auf die Karte die passende
  /// UserReport wiederfindet - analog zu _poiById.
  Map<String, UserReport> _reportById = {};

  // --- Kartensteuerung (Design-Ueberarbeitung) ---------------------------
  /// Ob die Legende (Punktfarben) gerade eingeblendet ist.
  bool _legendVisible = false;

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
    _map?.removeListener(_onCameraChanged);
    super.dispose();
  }

  // --- MapLibre-Callbacks --------------------------------------------------

  void _onMapCreated(MapLibreMapController controller) {
    _map = controller;
    _map!.onFeatureTapped.add(_onFeatureTapped);
    // Fuer den Massstabsbalken: Kamera-Updates (Zoom/Pan) sollen ein
    // Neuzeichnen ausloesen (siehe ScaleBar-Widget).
    _map!.addListener(_onCameraChanged);
  }

  void _onCameraChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onStyleLoaded() async {
    _loadTimer?.cancel();
    await _addUserLocationLayers();
    await _loadAndShowPois();
    await _loadAndShowReports();
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
    // Vor dem ersten 'await' lesen (lint use_build_context_synchronously):
    // context bleibt bis dahin garantiert gueltig.
    final brightness = Theme.of(context).brightness;

    await map.addSource(
      _userSourceId,
      const GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    final colorBySource = [
      'match',
      ['get', 'source'],
      'demo',
      MapColors.demo(brightness),
      MapColors.gps(brightness),
    ];

    await map.addCircleLayer(
      _userSourceId,
      _userHaloLayerId,
      CircleLayerProperties(
        circleRadius: 16,
        circleColor: colorBySource,
        circleOpacity: 0.25,
      ),
    );
    await map.addCircleLayer(
      _userSourceId,
      _userDotLayerId,
      CircleLayerProperties(
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
    // Vor dem ersten 'await' lesen (lint use_build_context_synchronously).
    final brightness = Theme.of(context).brightness;

    // Echte POIs aus OpenStreetMap/Overpass (Phase 5), begrenzt auf den
    // Landkreis OPR. Ist Overpass nicht erreichbar oder liefert nichts,
    // weichen wir auf die lokalen Test-POIs aus Phase 4 aus, damit die
    // Karte trotzdem nutzbar bleibt (PROJECT_BRAIN Regel 8).
    List<Poi> pois;
    try {
      pois = await _overpassService.loadPois(MapConstants.oprBounds);
      if (pois.isEmpty) {
        debugPrint('Overpass: 0 POIs in der Bounding Box erhalten.');
        pois = await _poiRepository.loadPois();
      }
    } on OverpassException catch (e) {
      // Grund im Debug-Log sichtbar machen (siehe `flutter run`-Konsole),
      // damit ein Fehlschlag nicht stillschweigend passiert.
      debugPrint('Overpass fehlgeschlagen: ${e.failure}');
      pois = await _poiRepository.loadPois();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OSM-Daten nicht erreichbar (${e.failure.name}) – '
              'zeige lokale Test-POIs.',
            ),
          ),
        );
      }
    }

    // Amtliche Badestellen Brandenburg und eine Overture-Teilmenge ergänzen
    // die OSM-POIs (PROJECT_BRAIN Abschnitt 11.2/11.4). Beide kommen aus
    // lokalen, per ETL-Skript (tools/) erzeugten GeoJSON-Dateien - kein
    // Netzwerkzugriff zur Laufzeit nötig, daher kein eigener Fehlerfall.
    // Bewusst keine Dublettenprüfung gegen OSM (PROJECT_BRAIN Abschnitt 33:
    // für den MVP dürfen Quellen getrennt dargestellt werden).
    final bathingSites = await _bathingSiteRepository.loadPois();
    final overturePois = await _overtureRepository.loadPois();
    pois = [...pois, ...bathingSites, ...overturePois];

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
    final colorByCategory = [
      'match',
      ['get', 'category'],
      'sehenswuerdigkeit', MapColors.poiSehenswuerdigkeit(brightness),
      'natur', MapColors.poiNatur(brightness),
      'badestelle', MapColors.poiBadestelle(brightness),
      'gastronomie', MapColors.poiGastronomie(brightness),
      MapColors.poiSonstiges(brightness), // Fallback ('sonstiges'/unbekannt)
    ];

    await map.addCircleLayer(
      _poiSourceId,
      _poiLayerId,
      CircleLayerProperties(
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

  // --- Nutzer-Meldungen (Phase 8) -----------------------------------------

  /// Laedt alle lokal gespeicherten Meldungen aus SQLite und zeigt sie als
  /// eigenen GeoJSON-Layer auf der Karte an (PROJECT_BRAIN Abschnitt 9:
  /// "Die Meldung soll anschliessend auf der Karte dargestellt werden").
  /// Wird beim Start und nach jeder neu gespeicherten Meldung aufgerufen.
  Future<void> _loadAndShowReports() async {
    final map = _map;
    if (map == null) return;
    // Vor dem ersten 'await' lesen (lint use_build_context_synchronously).
    final brightness = Theme.of(context).brightness;

    final reports = await _reportRepository.loadReports();
    _reportById = {
      for (final report in reports)
        if (report.id != null) 'report:${report.id}': report,
    };

    final data = {
      'type': 'FeatureCollection',
      'features': [for (final report in reports) report.toGeoJsonFeature()],
    };

    if (!_reportLayerAdded) {
      await map.addSource(
        _reportSourceId,
        GeojsonSourceProperties(data: data),
      );
      // Eigene, von den POI-Kategorien klar unterscheidbare Farbe
      // (dunkelrot), damit Nutzer-Meldungen auf der Karte sofort als
      // "eigener" Layer erkennbar sind.
      await map.addCircleLayer(
        _reportSourceId,
        _reportLayerId,
        CircleLayerProperties(
          circleRadius: 9,
          circleColor: MapColors.report(brightness),
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _reportLayerAdded = true;
    } else {
      await map.setGeoJsonSource(_reportSourceId, data);
    }
  }

  /// Oeffnet den "Melden"-Screen (Phase 8) mit dem aktuellen Standort.
  /// Wurde eine Meldung gespeichert, wird der Meldungen-Layer neu geladen,
  /// damit sie sofort auf der Karte erscheint.
  Future<void> _openReport() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportScreen(position: _location.position),
      ),
    );
    if (saved == true) {
      await _loadAndShowReports();
    }
  }

  /// Reagiert auf einen Tap auf eine Karten-Feature (POI-Layer) und öffnet
  /// die Detailansicht des zugehörigen POI.
  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) async {
    if (layerId == _reportLayerId) {
      final report = _reportById[id];
      if (report == null) return;
      final label = ReportCategory.labelFor(report.category);
      final comment = report.comment;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(comment == null ? label : '$label: $comment')),
      );
      return;
    }
    if (layerId != _poiLayerId) return;
    final poi = _poiById[id];
    if (poi == null) return;

    final position = _location.position;
    final route = await Navigator.of(context).push<RouteResult>(
      MaterialPageRoute(
        builder: (_) => PoiDetailScreen(
          poi: poi,
          currentPosition: position == null
              ? null
              : LatLng(position.latitude, position.longitude),
        ),
      ),
    );
    if (route != null) {
      await _showRoute(route);
    }
  }

  /// Zeichnet eine berechnete Route als Linie auf der Karte und zentriert
  /// die Kamera darauf (PROJECT_BRAIN Abschnitt 7).
  Future<void> _showRoute(RouteResult route) async {
    final map = _map;
    if (map == null || route.points.isEmpty) return;
    // Vor dem ersten 'await' lesen (lint use_build_context_synchronously).
    final brightness = Theme.of(context).brightness;

    final geojson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'profile': route.profile},
          'geometry': {
            'type': 'LineString',
            // GeoJSON-Koordinatenreihenfolge: [longitude, latitude].
            'coordinates': [
              for (final p in route.points) [p.longitude, p.latitude],
            ],
          },
        },
      ],
    };

    if (!_routeLayerAdded) {
      await map.addSource(
        _routeSourceId,
        GeojsonSourceProperties(data: geojson),
      );
      // Farbe je Verkehrsmittel, damit auf der Karte erkennbar bleibt,
      // welches Profil zuletzt berechnet wurde (Fuß = blau, Rad = grün).
      final colorByProfile = [
        'match',
        ['get', 'profile'],
        'bicycle', MapColors.routeRad(brightness),
        MapColors.routeFuss(brightness),
      ];
      await map.addLineLayer(
        _routeSourceId,
        _routeLayerId,
        LineLayerProperties(
          lineColor: colorByProfile,
          lineWidth: 4,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      _routeLayerAdded = true;
    } else {
      await map.setGeoJsonSource(_routeSourceId, geojson);
    }

    try {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFor(route.points),
          left: 32,
          top: 32,
          right: 32,
          bottom: 32,
        ),
      );
    } catch (e) {
      // Ein Problem beim Kamera-Zoom (z. B. bei einer sehr kurzen Route)
      // soll die Distanz-/Dauer-Anzeige unten nicht verhindern.
      debugPrint('Kamera-Anpassung an Route fehlgeschlagen: $e');
    }

    // Geofence (Phase 10, PROJECT_BRAIN Abschnitt 8) automatisch auf das
    // Routenziel aktivieren - sobald eine Route laeuft, soll die App bei
    // Ankunft benachrichtigen. Eine evtl. noch aktive Rundtour-
    // Zielkette (siehe _showTourRoute) wird dabei verworfen.
    _tourActive = false;
    _activeTourLabel = null;
    _tourQueue.clear();
    _tourQueueLabels.clear();
    _geofence.setTarget(route.points.last);

    if (!mounted) return;
    final km = (route.distanceMeters / 1000).toStringAsFixed(1);
    final minutes = (route.durationSeconds / 60).round();
    final modeText = route.profile == 'bicycle' ? 'mit dem Rad' : 'zu Fuß';
    debugPrint('Route berechnet: $km km, $minutes Min. ($modeText)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route $modeText: $km km, ca. $minutes Min.')),
    );
  }

  /// Zeichnet die Etappen einer gestarteten Rundtour als durchgehende
  /// Linie auf der Karte (gleiche Farblogik wie eine Einzelroute, siehe
  /// [_showRoute]) und baut die Geofence-Zielkette auf: das erste Ziel
  /// wird sofort aktiv, die weiteren Stopps (inkl. abschliessendem
  /// Rueckweg zum Start) werden in [_tourQueue] vorgemerkt und in
  /// [_checkGeofence] nacheinander aktiviert (mit dem Nutzer
  /// abgestimmt: automatischer Fortschritt zum naechsten Stopp).
  Future<void> _showTourRoute(TourRouteResult tour) async {
    final map = _map;
    if (map == null || tour.legs.isEmpty) return;
    // Vor dem ersten 'await' lesen (lint use_build_context_synchronously).
    final brightness = Theme.of(context).brightness;

    final allPoints = <LatLng>[
      for (final leg in tour.legs) ...leg.points,
    ];
    if (allPoints.isEmpty) return;

    final profile = tour.legs.first.profile;
    final geojson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'profile': profile},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final p in allPoints) [p.longitude, p.latitude],
            ],
          },
        },
      ],
    };

    if (!_routeLayerAdded) {
      await map.addSource(
        _routeSourceId,
        GeojsonSourceProperties(data: geojson),
      );
      final colorByProfile = [
        'match',
        ['get', 'profile'],
        'bicycle', MapColors.routeRad(brightness),
        MapColors.routeFuss(brightness),
      ];
      await map.addLineLayer(
        _routeSourceId,
        _routeLayerId,
        LineLayerProperties(
          lineColor: colorByProfile,
          lineWidth: 4,
          lineCap: 'round',
          lineJoin: 'round',
        ),
      );
      _routeLayerAdded = true;
    } else {
      await map.setGeoJsonSource(_routeSourceId, geojson);
    }

    try {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFor(allPoints),
          left: 32,
          top: 32,
          right: 32,
          bottom: 32,
        ),
      );
    } catch (e) {
      debugPrint('Kamera-Anpassung an Rundtour fehlgeschlagen: $e');
    }

    // Geofence-Kette aufbauen: erstes Ziel sofort aktiv, restliche Ziele
    // (weitere Stopps + abschliessender Rueckweg zum Start) vorgemerkt.
    final targets = [for (final leg in tour.legs) leg.points.last];
    final labels = [
      ...tour.stopNames,
      'Start (Rundtour abgeschlossen)',
    ];

    _tourActive = true;
    _activeTourLabel = labels.first;
    _geofence.setTarget(targets.first);
    _tourQueue
      ..clear()
      ..addAll(targets.skip(1));
    _tourQueueLabels
      ..clear()
      ..addAll(labels.skip(1));

    if (!mounted) return;
    final totalKm = (tour.legs.fold<double>(
                  0,
                  (sum, leg) => sum + leg.distanceMeters,
                ) /
                1000)
        .toStringAsFixed(1);
    final totalMinutes = (tour.legs.fold<double>(
                  0,
                  (sum, leg) => sum + leg.durationSeconds,
                ) /
                60)
        .round();
    final modeText = profile == 'bicycle' ? 'mit dem Rad' : 'zu Fuß';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rundtour $modeText: ${tour.stopNames.length} Stopps, '
          '$totalKm km, ca. $totalMinutes Min.',
        ),
      ),
    );
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
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
      // Wetter nur bei einem neuen Standort-„Fix" abfragen (nicht bei jedem
      // laufenden GPS-Update) - vermeidet unnötig viele Open-Meteo-Aufrufe
      // (PROJECT_BRAIN Abschnitt 35 - Performance).
      unawaited(_loadWeather(position));
    }

    // Geofence bei jedem Standort-Update pruefen (nicht nur beim ersten
    // Fix), damit die Ankunft am Routenziel erkannt wird.
    if (position != null) {
      _checkGeofence(position);
    }
  }

  /// Benachrichtigt, sobald die Position erstmals innerhalb des
  /// Geofence-Schwellenwerts um das aktive Routenziel liegt (Phase 10).
  ///
  /// Bei einer laufenden Rundtour (Rundtour-Funktion, mit dem Nutzer
  /// als "automatisch zum naechsten Stopp" abgestimmt) wird hier
  /// zusaetzlich der naechste Stopp aus [_tourQueue] aktiviert, bis die
  /// Kette (inkl. abschliessendem Rueckweg zum Start) abgearbeitet ist.
  void _checkGeofence(UserPosition position) {
    if (!_geofence.checkArrival(position)) return;
    if (!mounted) return;

    if (_tourQueue.isNotEmpty) {
      final reachedLabel = _activeTourLabel;
      final nextTarget = _tourQueue.removeAt(0);
      final nextLabel = _tourQueueLabels.removeAt(0);
      _activeTourLabel = nextLabel;
      _geofence.setTarget(nextTarget);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reachedLabel != null
                ? '$reachedLabel erreicht! Weiter zu $nextLabel.'
                : 'Ziel erreicht! Weiter zu $nextLabel.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final message = _tourActive ? 'Rundtour abgeschlossen!' : 'Ziel erreicht!';
    _tourActive = false;
    _activeTourLabel = null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  /// Lädt das aktuelle Wetter für [position] von Open-Meteo.
  Future<void> _loadWeather(UserPosition position) async {
    if (!mounted) return;
    setState(() {
      _weatherLoading = true;
      _weatherFailure = null;
    });
    try {
      final weather = await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _weatherLoading = false;
      });
    } on WeatherException catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherFailure = e.failure;
        _weatherLoading = false;
      });
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

  /// Eine Zoomstufe vergrößern/verkleinern (Zoom-Bedienelement).
  Future<void> _zoomIn() async {
    await _map?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    await _map?.animateCamera(CameraUpdate.zoomOut());
  }

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

  /// Oeffnet den "Entdecken"-Screen (Phase 7: Context Engine,
  /// PROJECT_BRAIN Abschnitt 5.3/29) mit den aktuell geladenen POIs,
  /// dem aktuellen Standort und Wetter. Wird dort eine Route berechnet,
  /// kommt sie hier zurueck und wird wie beim direkten POI-Tap auf der
  /// Karte gezeichnet.
  Future<void> _openDiscover() async {
    // Object statt RouteResult: die Entdecken-Seite kann sowohl eine
    // Einzelroute (RouteResult) als auch eine gestartete Rundtour
    // (TourRouteResult) zurueckgeben (Rundtour-Funktion).
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => DiscoverScreen(
          pois: _poiById.values.toList(),
          position: _location.position,
          weather: _weather,
        ),
      ),
    );
    if (result is RouteResult) {
      await _showRoute(result);
    } else if (result is TourRouteResult) {
      await _showTourRoute(result);
    }
  }

  /// Exportiert alle gespeicherten Meldungen als GeoJSON-Datei und
  /// oeffnet dafuer den Android-Share-Dialog (Phase 9, PROJECT_BRAIN
  /// Abschnitt 10). Fehlerfaelle (keine Meldungen, Datei konnte nicht
  /// geschrieben werden, Teilen abgebrochen/fehlgeschlagen) zeigen eine
  /// verstaendliche Meldung statt eines stillen Fehlschlags (Regel 8).
  Future<void> _exportReports() async {
    try {
      final reports = await _reportRepository.loadReports();
      await _exportService.exportAndShare(reports);
    } on ExportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_exportErrorText(e.failure))),
      );
    }
  }

  String _exportErrorText(ExportFailure failure) {
    switch (failure) {
      case ExportFailure.noReports:
        return 'Noch keine Meldungen zum Exportieren vorhanden.';
      case ExportFailure.writeFailed:
        return 'GeoJSON-Datei konnte nicht erstellt werden.';
      case ExportFailure.shareFailed:
        return 'Teilen fehlgeschlagen oder abgebrochen.';
    }
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPR NOW'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Entdecken - was kann ich jetzt machen?',
            onPressed: _openDiscover,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Meldungen als GeoJSON exportieren',
            onPressed: _exportReports,
          ),
          IconButton(
            icon: Icon(_legendVisible ? Icons.layers : Icons.layers_outlined),
            tooltip: 'Legende ein-/ausblenden',
            onPressed: () => setState(() => _legendVisible = !_legendVisible),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Über OPR NOW',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            ),
          ),
          _buildModeMenu(),
        ],
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
                  // Fuer den Massstabsbalken (ScaleBar) wird die aktuelle
                  // Kameraposition (Zoom, Breitengrad) benoetigt.
                  trackCameraPosition: true,
                ),
                if (!_styleLoaded)
                  Center(
                    child: _loadTimedOut
                        ? const _MapLoadHint()
                        : const CircularProgressIndicator(),
                  ),
                if (_styleLoaded)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _WeatherChip(
                      weather: _weather,
                      loading: _weatherLoading,
                      failure: _weatherFailure,
                    ),
                  ),
                if (_styleLoaded)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_legendVisible) ...[
                          const LegendPanel(),
                          const SizedBox(height: 8),
                        ],
                        ScaleBar(cameraPosition: _map?.cameraPosition),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZoomControl(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'fab-district',
            onPressed: _showWholeDistrict,
            tooltip: 'Gesamten Landkreis anzeigen',
            child: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'fab-report',
            onPressed: _openReport,
            tooltip: 'Meldung erfassen (Phase 8)',
            child: const Icon(Icons.add_location_alt),
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

/// Kleines Wetter-Badge oben links auf der Karte: Temperatur + Icon für den
/// aktuellen Standort (Phase 5). Zeigt Ladezustand bzw. Fehler kompakt an.
class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.weather,
    required this.loading,
    required this.failure,
  });

  final WeatherContext? weather;
  final bool loading;
  final WeatherFailure? failure;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (content == null) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: content,
      ),
    );
  }

  Widget? _buildContent() {
    if (loading && weather == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (weather != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_weatherIcon(weather!.weatherCode), size: 18),
          const SizedBox(width: 6),
          Text('${weather!.temperature.round()} °C'),
        ],
      );
    }
    if (failure != null) {
      return const Icon(Icons.cloud_off, size: 18);
    }
    return null;
  }

  IconData _weatherIcon(int code) {
    // Vereinfachte Zuordnung nach WMO-Wettercode (Open-Meteo-Doku).
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code == 45 || code == 48) return Icons.cloud;
    if (code >= 51 && code <= 57) return Icons.grain;
    if (code >= 61 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.umbrella;
    if (code >= 85 && code <= 86) return Icons.ac_unit;
    if (code >= 95) return Icons.flash_on;
    return Icons.cloud;
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
