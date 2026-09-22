import 'package:flutter/material.dart';

/// Kompaktes Zoom-Bedienelement (+/-) fuer die Karte.
///
/// Bewusst als schlichte Material-Card mit zwei Standard-Icons statt
/// grosser bunter Schaltflaechen - passend zum mit dem Nutzer
/// abgestimmten Anspruch "professionell, nicht wie eine KI-generierte
/// Webseite".
class ZoomControl extends StatelessWidget {
  const ZoomControl({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Feste Breite noetig: ohne sie zwingt der Container(height: 1) unten
    // (als Trennlinie) die Column auf die volle verfuegbare Breite des
    // floatingActionButton-Slots, statt sich am Icon zu orientieren.
    return Material(
      color: colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Vergrößern',
              onPressed: onZoomIn,
            ),
            Container(height: 1, color: colorScheme.outlineVariant),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: 'Verkleinern',
              onPressed: onZoomOut,
            ),
          ],
        ),
      ),
    );
  }
}
