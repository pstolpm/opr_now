import 'dart:math' show cos, pi, pow;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Massstabsbalken fuer die Karte.
///
/// MapLibre Flutter bietet zwar `scaleControlEnabled` an, laut
/// Paket-Dokumentation ist das aber "Web only - has no effect on other
/// platforms" - fuer Android (Zielplattform, PROJECT_BRAIN Abschnitt 2)
/// muss der Massstab daher selbst berechnet und gezeichnet werden.
///
/// Rechnet die Meter-pro-Pixel-Aufloesung aus Zoomstufe und Breitengrad
/// (Standard-Web-Mercator-Formel) und rundet auf eine "schoene" Distanz,
/// die in eine Ziel-Balkenbreite passt - so wie bei gaengigen
/// Kartenanwendungen.
class ScaleBar extends StatelessWidget {
  const ScaleBar({super.key, required this.cameraPosition});

  /// Aktuelle Kameraposition; null, solange MapLibre noch keine erste
  /// Position gemeldet hat (dann wird nichts angezeigt).
  final CameraPosition? cameraPosition;

  static const double _maxWidthPx = 90;

  /// "Schoene" Rundwerte in Metern (1/2/5 * 10^n), ueblich bei
  /// Kartenmassstaeben.
  static const List<double> _niceMeters = [
    1, 2, 5, 10, 20, 50, 100, 200, 500,
    1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000,
  ];

  @override
  Widget build(BuildContext context) {
    final position = cameraPosition;
    if (position == null) return const SizedBox.shrink();

    final metersPerPixel = _metersPerPixel(position.target.latitude, position.zoom);
    final fit = _fitDistance(metersPerPixel, _maxWidthPx);
    if (fit == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPaint(
              size: Size(fit.widthPx, 6),
              painter: _ScaleBarPainter(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 3),
            Text(fit.label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  /// Standard-Web-Mercator-Aufloesung: Meter pro Pixel bei 256-px-Kacheln,
  /// abhaengig von Zoomstufe und Breitengrad (Verzerrung durch die
  /// Projektion).
  static double _metersPerPixel(double latitudeDeg, double zoom) {
    return 156543.03392 * cos(latitudeDeg * pi / 180) / pow(2, zoom);
  }

  /// Waehlt die groesste "schoene" Distanz, die noch in [maxWidthPx] passt,
  /// und berechnet die dazu passende Balkenbreite.
  static _ScaleFit? _fitDistance(double metersPerPixel, double maxWidthPx) {
    if (metersPerPixel <= 0) return null;
    final maxMeters = metersPerPixel * maxWidthPx;

    var chosen = _niceMeters.first;
    for (final meters in _niceMeters) {
      if (meters > maxMeters) break;
      chosen = meters;
    }

    final widthPx = chosen / metersPerPixel;
    return _ScaleFit(widthPx: widthPx, label: _formatLabel(chosen));
  }

  static String _formatLabel(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final text =
          km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
      return '$text km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}

class _ScaleFit {
  const _ScaleFit({required this.widthPx, required this.label});

  final double widthPx;
  final String label;
}

/// Zeichnet einen einfachen Massstabsbalken (waagerechte Linie mit
/// Endstrichen), analog zu gaengigen Kartenanwendungen.
class _ScaleBarPainter extends CustomPainter {
  const _ScaleBarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ScaleBarPainter oldDelegate) => oldDelegate.color != color;
}
