import 'package:flutter/material.dart';

import '../models/poi.dart';

/// Detailansicht für einen einzelnen POI.
///
/// Phase 4: zeigt Name, Kategorie, Beschreibung, Koordinaten und Quelle.
/// Spätere Phasen ergänzen Entfernung, Reisezeit, Wettertauglichkeit und
/// einen Routing-Start-Button (PROJECT_BRAIN Abschnitt 29).
class PoiDetailScreen extends StatelessWidget {
  const PoiDetailScreen({super.key, required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(poi.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow(label: 'Kategorie', value: _categoryLabel(poi.category)),
          if (poi.description != null)
            _InfoRow(label: 'Beschreibung', value: poi.description!),
          _InfoRow(
            label: 'Koordinaten',
            value: '${poi.latitude.toStringAsFixed(5)}, '
                '${poi.longitude.toStringAsFixed(5)}',
          ),
          _InfoRow(label: 'Quelle', value: poi.source),
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
