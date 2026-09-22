import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Legende fuer die Punktfarben auf der Karte (POI-Kategorien, Meldungen,
/// Routen) - ueber einen App-Bar-Button ein-/ausblendbar.
///
/// Grund fuer diese Legende: die Design-Ueberarbeitung hat die
/// Punktfarben neu vergeben, damit sie sich untereinander nicht mehr
/// aehneln (siehe [MapColors]-Kommentar) - die Legende macht die
/// Zuordnung fuer Nutzer:innen nachvollziehbar.
class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Color pick(Color light, Color dark) => isDark ? dark : light;

    final entries = <_LegendEntry>[
      _LegendEntry(
        'Sehenswürdigkeit',
        pick(MapColors.poiSehenswuerdigkeitLight, MapColors.poiSehenswuerdigkeitDark),
      ),
      _LegendEntry(
        'Natur / Aussichtspunkt',
        pick(MapColors.poiNaturLight, MapColors.poiNaturDark),
      ),
      _LegendEntry(
        'Badestelle',
        pick(MapColors.poiBadestelleLight, MapColors.poiBadestelleDark),
      ),
      _LegendEntry(
        'Gastronomie',
        pick(MapColors.poiGastronomieLight, MapColors.poiGastronomieDark),
      ),
      _LegendEntry(
        'Sonstiges',
        pick(MapColors.poiSonstigesLight, MapColors.poiSonstigesDark),
      ),
      _LegendEntry('Meldung', pick(MapColors.reportLight, MapColors.reportDark)),
      _LegendEntry(
        'Route zu Fuß',
        pick(MapColors.routeFussLight, MapColors.routeFussDark),
      ),
      _LegendEntry(
        'Route Fahrrad',
        pick(MapColors.routeRadLight, MapColors.routeRadDark),
      ),
    ];

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legende', style: textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(entry.label, style: textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry(this.label, this.color);

  final String label;
  final Color color;
}
