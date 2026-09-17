import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../utils/constants.dart';

/// Zentrale Kartenansicht der App (Phase 2).
///
/// Zeigt eine MapLibre-Vektorkarte, zentriert auf den Landkreis
/// Ostprignitz-Ruppin. Weitere Layer (POIs, Standort, Route, Meldungen)
/// werden in den folgenden Phasen ergänzt.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Controller zum Steuern der Karte (Kamera, Layer). Wird von
  /// MapLibre nach dem Erzeugen der nativen Kartenansicht geliefert.
  MapLibreMapController? _controller;

  /// true, sobald der Kartenstil (inkl. erster Kacheln) geladen ist.
  bool _styleLoaded = false;

  /// true, wenn der Stil nach einer Wartezeit noch nicht geladen ist -
  /// dann fehlt vermutlich die Internetverbindung.
  bool _loadTimedOut = false;

  Timer? _loadTimer;

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
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  void _onStyleLoaded() {
    _loadTimer?.cancel();
    if (mounted) {
      setState(() {
        _styleLoaded = true;
        _loadTimedOut = false;
      });
    }
  }

  /// Kamera zurück auf den gesamten Landkreis setzen.
  Future<void> _showWholeDistrict() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapConstants.oprBounds,
        left: 24,
        top: 24,
        right: 24,
        bottom: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPR NOW'),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MapConstants.styleUrl,
            initialCameraPosition: const CameraPosition(
              target: MapConstants.oprCenter,
              zoom: MapConstants.initialZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            // Standort-Layer kommt in Phase 3 (Berechtigungen nötig).
            myLocationEnabled: false,
            // Dreh- und Neigegesten für den MVP deaktivieren:
            // vereinfacht die Bedienung, "Norden oben" bleibt erhalten.
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showWholeDistrict,
        tooltip: 'Gesamten Landkreis anzeigen',
        child: const Icon(Icons.zoom_out_map),
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
