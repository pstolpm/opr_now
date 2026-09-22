import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_report.dart';

/// Fehlerfaelle beim Export (PROJECT_BRAIN Regel 8: jeder Schritt kann
/// fehlschlagen, dafuer braucht es verstaendliche Fehlermeldungen).
enum ExportFailure { noReports, writeFailed, shareFailed }

class ExportException implements Exception {
  const ExportException(this.failure);
  final ExportFailure failure;
}

/// Exportiert selbst erfasste Meldungen als GeoJSON-Datei (PROJECT_BRAIN
/// Abschnitt 10, Phase 9).
///
/// Die Datei wird im App-eigenen Temp-Verzeichnis erzeugt und ueber den
/// Android-Share-Dialog angeboten - der Nutzer entscheidet dort, wo er sie
/// speichert oder an wen er sie schickt. Das kommt ohne eigenes Backend
/// (Regel 3) und ohne dauerhafte Speicherberechtigung aus.
class ExportService {
  const ExportService();

  /// Baut die GeoJSON-FeatureCollection fuer [reports] (PROJECT_BRAIN
  /// Abschnitt 10: Feature/geometry/properties, Koordinaten in
  /// [longitude, latitude], siehe UserReport.toGeoJsonFeature).
  Map<String, dynamic> buildGeoJson(List<UserReport> reports) {
    return {
      'type': 'FeatureCollection',
      'features': [for (final report in reports) report.toGeoJsonFeature()],
    };
  }

  /// Schreibt [reports] als GeoJSON-Datei und oeffnet den Android-Share-
  /// Dialog dafuer.
  Future<void> exportAndShare(List<UserReport> reports) async {
    if (reports.isEmpty) {
      throw const ExportException(ExportFailure.noReports);
    }

    final geoJson = buildGeoJson(reports);
    final encoded = const JsonEncoder.withIndent('  ').convert(geoJson);

    File file;
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      file = File('${dir.path}/opr_now_meldungen_$timestamp.geojson');
      await file.writeAsString(encoded);
    } catch (e) {
      throw const ExportException(ExportFailure.writeFailed);
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'OPR NOW - ${reports.length} Meldung(en) als GeoJSON',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      throw const ExportException(ExportFailure.shareFailed);
    }
  }
}
