import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/poi.dart';
import '../services/routing_service.dart';

/// Detailansicht für einen einzelnen POI.
///
/// Phase 4: zeigt Name, Kategorie, Beschreibung, Koordinaten und Quelle.
/// Spätere Phasen ergänzen Entfernung, Reisezeit, Wettertauglichkeit und
/// einen Routing-Start-Button (PROJECT_BRAIN Abschnitt 29).
class PoiDetailScreen extends StatefulWidget {
  const PoiDetailScreen({super.key, required this.poi, this.currentPosition});

  final Poi poi;

  /// Aktueller Standort (GPS oder Demo) im Moment des Öffnens - Startpunkt
  /// für die Routenberechnung. Null, wenn (noch) kein Standort vorliegt.
  final LatLng? currentPosition;

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final _routingService = RoutingService();
  bool _routing = false;

  Poi get poi => widget.poi;

  Future<void> _calculateRoute(String profile) async {
    final start = widget.currentPosition;
    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Standort verfügbar.')),
      );
      return;
    }

    setState(() => _routing = true);
    try {
      final route = await _routingService.getRoute(
        start: start,
        destination: LatLng(poi.latitude, poi.longitude),
        profile: profile,
      );
      if (!mounted) return;
      Navigator.of(context).pop(route);
    } on RoutingException catch (e) {
      if (!mounted) return;
      setState(() => _routing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_routingErrorText(e.failure))),
      );
    }
  }

  String _routingErrorText(RoutingFailure failure) {
    switch (failure) {
      case RoutingFailure.noRoute:
        return 'Keine Route gefunden.';
      case RoutingFailure.timeout:
        return 'Routing-Dienst antwortet nicht (Zeitlimit).';
      case RoutingFailure.network:
        return 'Keine Verbindung zum Routing-Dienst.';
      case RoutingFailure.invalidResponse:
      case RoutingFailure.unknown:
        return 'Route konnte nicht berechnet werden.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(poi.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _routing ? null : () => _calculateRoute('pedestrian'),
                  icon: _routing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.directions_walk),
                  label: const Text('Zu Fuß'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _routing ? null : () => _calculateRoute('bicycle'),
                  icon: const Icon(Icons.directions_bike),
                  label: const Text('Fahrrad'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Kategorie', value: _categoryLabel(poi.category)),
          if (poi.description != null)
            _InfoRow(label: 'Beschreibung', value: poi.description!),
          _InfoRow(
            label: 'Koordinaten',
            value: '${poi.latitude.toStringAsFixed(5)}, '
                '${poi.longitude.toStringAsFixed(5)}',
          ),
          _InfoRow(label: 'Quelle', value: poi.source),
          if (poi.details != null && poi.details!.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Weitere Informationen',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final entry in poi.details!.entries)
              _InfoRow(label: entry.key, value: entry.value),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'sehenswuerdigkeit':
        return 'Sehenswürdigkeit';
      case 'natur':
        return 'Natur / Aussichtspunkt';
      case 'badestelle':
        return 'Badestelle';
      case 'gastronomie':
        return 'Gastronomie';
      default:
        return category;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
