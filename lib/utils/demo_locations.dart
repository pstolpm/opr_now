/// Vorbelegter Demo-Standort für den Demo-Modus (PROJECT_BRAIN Abschnitt 26).
class DemoLocation {
  const DemoLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;

  /// Anzeigename in der UI.
  final String name;

  final double latitude;
  final double longitude;
}

/// Feste Demo-Standorte im Landkreis Ostprignitz-Ruppin.
///
/// Ein frei setzbarer Testpunkt wird später ergänzt.
const List<DemoLocation> demoLocations = [
  DemoLocation(
    id: 'neuruppin',
    name: 'Neuruppin (Zentrum)',
    latitude: 52.9265,
    longitude: 12.8033,
  ),
  DemoLocation(
    id: 'rheinsberg',
    name: 'Rheinsberg (Schloss)',
    latitude: 53.0978,
    longitude: 12.8930,
  ),
];
