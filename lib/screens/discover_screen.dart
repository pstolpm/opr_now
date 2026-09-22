import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../logic/context_engine.dart';
import '../models/poi.dart';
import '../models/recommendation.dart';
import '../models/route_result.dart';
import '../models/user_position.dart';
import '../models/weather_context.dart';
import 'poi_detail_screen.dart';

/// "Entdecken"-Screen: die kontextbasierte Kernfunktion aus PROJECT_BRAIN
/// Abschnitt 5.3 / 29 ("Was kann ich jetzt machen?").
///
/// Der Nutzer gibt Zeitbudget, Fortbewegungsart und Interessen an. Die
/// ContextEngine bewertet daraufhin die aktuell geladenen POIs (Phase 7).
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

  static const _timeOptions = [30, 60, 90, 120, 180];
  static const _categories = {
    'sehenswuerdigkeit': 'Sehenswuerdigkeiten',
    'natur': 'Natur',
    'badestelle': 'Baden',
    'gastronomie': 'Gastronomie',
  };

  int _timeBudgetMinutes = 90;
  String _mobility = 'pedestrian';
  final Set<String> _interests = {};

  List<Recommendation>? _results;

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
                          onPressed: _showRecommendations,
                          child: const Text('Vorschlaege anzeigen'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildResults()),
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
