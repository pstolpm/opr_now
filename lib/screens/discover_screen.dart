import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../logic/context_engine.dart';
import '../logic/tour_planner.dart';
import '../models/poi.dart';
import '../models/recommendation.dart';
import '../models/route_result.dart';
import '../models/tour_route_result.dart';
import '../models/tour_stop.dart';
import '../models/user_position.dart';
import '../models/weather_context.dart';
import '../services/routing_service.dart';
import 'poi_detail_screen.dart';

/// "Entdecken"-Screen: die kontextbasierte Kernfunktion aus PROJECT_BRAIN
/// Abschnitt 5.3 / 29 ("Was kann ich jetzt machen?").
///
/// Der Nutzer gibt Zeitbudget, Fortbewegungsart und Interessen an. Zwei
/// Modi teilen sich diese Eingaben:
/// - "Einzelziel": die ContextEngine bewertet die geladenen POIs (Phase 7).
/// - "Rundtour": der [TourPlanner] kombiniert mehrere Stopps zu einer
///   Rundtour mit Rueckweg zum Start (PROJECT_BRAIN Abschnitt 23,
///   vorgezogene Erweiterung 2, mit dem Nutzer als regelbasierter
///   Greedy-Algorithmus abgestimmt).
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.pois,
    required this.position,
    required this.weather,
  });

  final List<Poi> pois;

  /// Aktueller Standort (GPS oder Demo). Ohne Standort kann keine Distanz
  /// berechnet werden - der Screen zeigt dann nur einen Hinweis.
  final UserPosition? position;

  final WeatherContext? weather;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const _engine = ContextEngine();
  static const _tourPlanner = TourPlanner();
  final _routingService = RoutingService();

  static const _timeOptions = [30, 60, 90, 120, 180];
  static const _categories = {
    'sehenswuerdigkeit': 'Sehenswuerdigkeiten',
    'natur': 'Natur',
    'badestelle': 'Baden',
    'gastronomie': 'Gastronomie',
  };

  /// 'single' = ein empfohlenes Ziel, 'tour' = mehrere Stopps
  /// kombiniert (Rundtour).
  String _mode = 'single';

  int _timeBudgetMinutes = 90;
  String _mobility = 'pedestrian';
  final Set<String> _interests = {};

  List<Recommendation>? _results;

  TourResult? _tourResult;
  bool _startingTour = false;
  String? _tourStartError;

  void _showRecommendations() {
    final position = widget.position;
    if (position == null) return;

    setState(() {
      _results = _engine.recommend(
        pois: widget.pois,
        position: position,
        timeBudget: Duration(minutes: _timeBudgetMinutes),
        mobility: _mobility,
        interests: _interests,
        weather: widget.weather,
      );
    });
  }

  void _planTour() {
    final position = widget.position;
    if (position == null) return;

    setState(() {
      _tourStartError = null;
      _tourResult = _tourPlanner.plan(
        pois: widget.pois,
        start: position,
        timeBudget: Duration(minutes: _timeBudgetMinutes),
        mobility: _mobility,
        interests: _interests,
        weather: widget.weather,
      );
    });
  }

  Future<void> _openPoi(Recommendation recommendation) async {
    final position = widget.position;
    final route = await Navigator.of(context).push<RouteResult>(
      MaterialPageRoute(
        builder: (_) => PoiDetailScreen(
          poi: recommendation.poi,
          currentPosition: position == null
              ? null
              : LatLng(position.latitude, position.longitude),
        ),
      ),
    );
    // Eine hier berechnete Route soll auf der Karte erscheinen - dafuer
    // reichen wir sie an den MapScreen zurueck, der diesen Screen geoeffnet
    // hat (siehe map_screen.dart, _openDiscover).
    if (route != null && mounted) {
      Navigator.of(context).pop(route);
    }
  }

  /// Berechnet die tatsaechlichen Etappen der geplanten Rundtour nach-
  /// einander ueber Valhalla (Start -> Stopp 1 -> ... -> zurueck zum
  /// Start) und gibt das Ergebnis an den MapScreen zurueck, der es dort
  /// zeichnet und den Geofence fuer den ersten Stopp aktiviert.
  Future<void> _startTour() async {
    final position = widget.position;
    final tour = _tourResult;
    if (position == null || tour == null || tour.stops.isEmpty) return;

    setState(() {
      _startingTour = true;
      _tourStartError = null;
    });

    final legs = <RouteResult>[];
    final stopNames = <String>[];
    var from = LatLng(position.latitude, position.longitude);

    try {
      for (final stop in tour.stops) {
        final to = LatLng(stop.poi.latitude, stop.poi.longitude);
        final leg = await _routingService.getRoute(
          start: from,
          destination: to,
          profile: _mobility,
        );
        legs.add(leg);
        stopNames.add(stop.poi.name);
        from = to;
      }
      // Letzte Etappe: zurueck zum urspruenglichen Startpunkt (mit dem
      // Nutzer abgestimmt: Rundtour endet immer am Start).
      final backToStart = LatLng(position.latitude, position.longitude);
      final returnLeg = await _routingService.getRoute(
        start: from,
        destination: backToStart,
        profile: _mobility,
      );
      legs.add(returnLeg);

      if (!mounted) return;
      Navigator.of(context).pop(
        TourRouteResult(legs: legs, stopNames: stopNames),
      );
    } on RoutingException catch (e) {
      if (!mounted) return;
      setState(() {
        _startingTour = false;
        _tourStartError = _routingErrorText(e.failure);
      });
    }
  }

  String _routingErrorText(RoutingFailure failure) {
    switch (failure) {
      case RoutingFailure.noRoute:
        return 'Für mindestens eine Etappe wurde keine Route gefunden.';
      case RoutingFailure.timeout:
        return 'Routing-Dienst antwortet nicht (Zeitlimit).';
      case RoutingFailure.network:
        return 'Keine Verbindung zum Routing-Dienst.';
      case RoutingFailure.invalidResponse:
      case RoutingFailure.unknown:
        return 'Rundtour konnte nicht berechnet werden.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entdecken')),
      body: widget.position == null
          ? const _NoPositionHint()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'single',
                            label: Text('Einzelziel'),
                            icon: Icon(Icons.place_outlined),
                          ),
                          ButtonSegment(
                            value: 'tour',
                            label: Text('Rundtour'),
                            icon: Icon(Icons.alt_route),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) => setState(() {
                          _mode = selection.first;
                          _tourStartError = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wie viel Zeit hast du?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final minutes in _timeOptions)
                            ChoiceChip(
                              label: Text('$minutes Min.'),
                              selected: _timeBudgetMinutes == minutes,
                              onSelected: (_) =>
                                  setState(() => _timeBudgetMinutes = minutes),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wie moechtest du dich bewegen?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'pedestrian',
                            label: Text('Zu Fuss'),
                            icon: Icon(Icons.directions_walk),
                          ),
                          ButtonSegment(
                            value: 'bicycle',
                            label: Text('Fahrrad'),
                            icon: Icon(Icons.directions_bike),
                          ),
                        ],
                        selected: {_mobility},
                        onSelectionChanged: (selection) =>
                            setState(() => _mobility = selection.first),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Was interessiert dich? (optional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final entry in _categories.entries)
                            FilterChip(
                              label: Text(entry.value),
                              selected: _interests.contains(entry.key),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _interests.add(entry.key);
                                } else {
                                  _interests.remove(entry.key);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _mode == 'single' ? _showRecommendations : _planTour,
                          child: Text(
                            _mode == 'single'
                                ? 'Vorschlaege anzeigen'
                                : 'Rundtour planen',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _mode == 'single' ? _buildResults() : _buildTourResults(),
                ),
              ],
            ),
    );
  }

  Widget _buildResults() {
    final results = _results;
    if (results == null) {
      return const Center(
        child: Text('Angaben auswaehlen und auf "Vorschlaege anzeigen" tippen.'),
      );
    }
    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Keine passenden Ziele im Zeitbudget gefunden. '
            'Versuch mehr Zeit oder ein anderes Verkehrsmittel.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) => _RecommendationTile(
        recommendation: results[index],
        onTap: () => _openPoi(results[index]),
      ),
    );
  }

  Widget _buildTourResults() {
    final tour = _tourResult;
    if (tour == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Angaben auswaehlen und auf "Rundtour planen" tippen.'),
        ),
      );
    }
    if (tour.stops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Keine Rundtour im Zeitbudget moeglich. Versuch mehr Zeit oder '
            'ein anderes Verkehrsmittel.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalKm = (tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final totalMinutes = (tour.totalTravelTimeSeconds / 60).round();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${tour.stops.length} Stopps · ca. $totalKm km · ca. '
            '$totalMinutes Min. (inkl. Rückweg zum Start)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tour.stops.length,
            itemBuilder: (context, index) => _TourStopTile(
              index: index,
              stop: tour.stops[index],
            ),
          ),
        ),
        if (_tourStartError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _tourStartError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startingTour ? null : _startTour,
              icon: _startingTour
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alt_route),
              label: const Text('Rundtour starten'),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recommendation, required this.onTap});

  final Recommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final poi = recommendation.poi;
    final km = (recommendation.distanceMeters / 1000).toStringAsFixed(1);
    final minutes = (recommendation.travelTimeSeconds / 60).round();
    final scorePercent = (recommendation.overallScore * 100).round();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Icon(_categoryIcon(poi.category))),
      title: Text(poi.name),
      subtitle: Text(
        '$km km * ca. $minutes Min. (einfach) - ${recommendation.reason}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$scorePercent%', style: Theme.of(context).textTheme.titleMedium),
          const Text('Eignung', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'sehenswuerdigkeit':
        return Icons.museum;
      case 'natur':
        return Icons.landscape;
      case 'badestelle':
        return Icons.pool;
      case 'gastronomie':
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }
}

class _TourStopTile extends StatelessWidget {
  const _TourStopTile({required this.index, required this.stop});

  final int index;
  final TourStop stop;

  @override
  Widget build(BuildContext context) {
    final km = (stop.legDistanceMeters / 1000).toStringAsFixed(1);
    final minutes = (stop.legTravelTimeSeconds / 60).round();

    return ListTile(
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(stop.poi.name),
      subtitle: Text('$km km · ca. $minutes Min. ab vorherigem Punkt - ${stop.reason}'),
    );
  }
}

class _NoPositionHint extends StatelessWidget {
  const _NoPositionHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Kein Standort verfuegbar. Bitte GPS aktivieren oder einen '
          'Demo-Standort waehlen.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
