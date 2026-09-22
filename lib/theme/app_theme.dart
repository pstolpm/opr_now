import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zentrale Design-Tokens fuer OPR NOW.
///
/// Mit dem Nutzer abgestimmt: Natur/Outdoor-Thema (Waldgruen als
/// App-Grundfarbe), Schriftart Poppins, Unterstuetzung fuer Light + Dark
/// Mode (folgt der System-Einstellung, siehe app.dart).
///
/// Bewusst zwei getrennte Farb-Systeme:
/// - [light]/[dark]: die App-Grundfarben (AppBar, Buttons, Chips) - ueber
///   Material 3 `ColorScheme.fromSeed` aus einer einzigen Waldgruen-
///   Seed-Farbe generiert.
/// - [MapColors]: die Punktfarben auf der Karte (Standort/POI-Kategorie/
///   Route/Meldung) - bewusst NICHT aus dem Seed abgeleitet, sondern fest
///   vergeben. So bleiben UI-Grundfarbe und Kartendaten klar getrennt und
///   die Kartenfarben sind auch untereinander eindeutig unterscheidbar
///   (vorher: Demo-Standort/Gastronomie beide orange, Fussweg-Route/
///   Badestelle beide blau, Fahrrad-Route/Natur-POI beide gruen).
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF2F6B4E); // Waldgruen

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Feste Punktfarben fuer die Kartendarstellung. Je Rolle eine Light- und
/// eine Dark-Variante (etwas heller/entsaettigt fuer guten Kontrast auf
/// dunklem Hintergrund, Material-3-Konvention).
///
/// Die statischen Methoden geben direkt einen MapLibre-tauglichen
/// Hex-String zurueck (z. B. fuer `CircleLayerProperties.circleColor`) -
/// map_screen.dart waehlt damit einmalig beim Layer-Aufbau die zur
/// aktuellen Theme-Helligkeit passende Variante.
class MapColors {
  MapColors._();

  static const gpsLight = Color(0xFF2C7DA0);
  static const gpsDark = Color(0xFF6FB6DA);

  static const demoLight = Color(0xFFE8A33D);
  static const demoDark = Color(0xFFF2BE6C);

  static const poiSehenswuerdigkeitLight = Color(0xFF6B4C82);
  static const poiSehenswuerdigkeitDark = Color(0xFFB497CC);

  static const poiNaturLight = Color(0xFF5B8C5A);
  static const poiNaturDark = Color(0xFF8FC08B);

  static const poiBadestelleLight = Color(0xFF1A8FA3);
  static const poiBadestelleDark = Color(0xFF5FC3D6);

  static const poiGastronomieLight = Color(0xFFC1652F);
  static const poiGastronomieDark = Color(0xFFE79A66);

  static const poiSonstigesLight = Color(0xFF78716C);
  static const poiSonstigesDark = Color(0xFFA8A29A);

  static const routeFussLight = Color(0xFF8B5E34);
  static const routeFussDark = Color(0xFFC39A6C);

  static const routeRadLight = Color(0xFFD64550);
  static const routeRadDark = Color(0xFFF08A93);

  static const reportLight = Color(0xFF7A2E3A);
  static const reportDark = Color(0xFFE28995);

  static bool _isDark(Brightness brightness) => brightness == Brightness.dark;

  static String gps(Brightness b) => _hex(_isDark(b) ? gpsDark : gpsLight);
  static String demo(Brightness b) => _hex(_isDark(b) ? demoDark : demoLight);

  static String poiSehenswuerdigkeit(Brightness b) =>
      _hex(_isDark(b) ? poiSehenswuerdigkeitDark : poiSehenswuerdigkeitLight);
  static String poiNatur(Brightness b) =>
      _hex(_isDark(b) ? poiNaturDark : poiNaturLight);
  static String poiBadestelle(Brightness b) =>
      _hex(_isDark(b) ? poiBadestelleDark : poiBadestelleLight);
  static String poiGastronomie(Brightness b) =>
      _hex(_isDark(b) ? poiGastronomieDark : poiGastronomieLight);
  static String poiSonstiges(Brightness b) =>
      _hex(_isDark(b) ? poiSonstigesDark : poiSonstigesLight);

  static String routeFuss(Brightness b) =>
      _hex(_isDark(b) ? routeFussDark : routeFussLight);
  static String routeRad(Brightness b) =>
      _hex(_isDark(b) ? routeRadDark : routeRadLight);

  static String report(Brightness b) =>
      _hex(_isDark(b) ? reportDark : reportLight);

  /// MapLibre-Layer-Properties erwarten Farben als Hex-String
  /// ('#RRGGBB'), nicht als Flutter-[Color].
  static String _hex(Color color) {
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
