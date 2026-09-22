import 'poi.dart';

/// Ergebnis der Context Engine fuer einen einzelnen POI: der POI selbst
/// plus Distanz, geschaetzte Reisezeit und die Bewertung, aus der sich die
/// Sortierung ergibt (PROJECT_BRAIN Abschnitt 6 und 21).
///
/// Die Teil-Scores bleiben absichtlich sichtbar (nicht nur [overallScore]),
/// damit in der UI nachvollziehbar bleibt, *warum* ein POI empfohlen wird
/// (PROJECT_BRAIN Regel 6: "Nutzer muss Code verstehen koennen").
class Recommendation {
  const Recommendation({
    required this.poi,
    required this.distanceMeters,
    required this.travelTimeSeconds,
    required this.overallScore,
    required this.distanceScore,
    required this.interestScore,
    required this.weatherScore,
    required this.contextScore,
    required this.reason,
  });

  final Poi poi;

  /// Geodaetische Luftlinie zum POI in Metern (nicht die tatsaechliche
  /// Routenlaenge - die wird erst bei Bedarf ueber Valhalla berechnet,
  /// siehe PoiDetailScreen).
  final double distanceMeters;

  /// Grobe Schaetzung der einfachen Reisezeit anhand einer angenommenen
  /// Durchschnittsgeschwindigkeit (siehe ContextEngine). Dient nur der
  /// Auswahl/Sortierung, nicht der Navigation.
  final double travelTimeSeconds;

  /// Gesamtscore 0..1, siehe PROJECT_BRAIN Abschnitt 6:
  /// 0,40 * DistanzScore + 0,30 * InteressenScore + 0,20 * WetterScore
  /// + 0,10 * weiterer KontextScore.
  final double overallScore;

  final double distanceScore;
  final double interestScore;
  final double weatherScore;
  final double contextScore;

  /// Kurze, fuer den Nutzer verstaendliche Begruendung der Empfehlung.
  final String reason;
}
