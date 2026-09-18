import 'package:flutter/material.dart';

import '../screens/map_screen.dart';
import '../services/location_controller.dart';
import '../services/location_source.dart';

/// Wurzel-Widget von OPR NOW.
///
/// Erzeugt die app-weiten Dienste (aktuell den [LocationController]) und
/// reicht sie an die Screens weiter. Ein StatefulWidget, damit die Dienste
/// genau einmal erzeugt und beim Beenden sauber freigegeben werden.
class OprNowApp extends StatefulWidget {
  const OprNowApp({super.key});

  @override
  State<OprNowApp> createState() => _OprNowAppState();
}

class _OprNowAppState extends State<OprNowApp> {
  late final LocationController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = LocationController(gpsSource: GpsLocationSource());
    // Standortupdates direkt beim App-Start anfordern. Fehler (z. B.
    // verweigerte Berechtigung) landen im Controller und werden im
    // MapScreen angezeigt.
    _locationController.startTracking();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPR NOW',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: MapScreen(locationController: _locationController),
    );
  }
}
