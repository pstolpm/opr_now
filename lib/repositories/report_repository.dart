import '../models/user_report.dart';
import '../services/storage_service.dart';

/// Vermittelt zwischen UI und lokaler Speicherung fuer Nutzer-Meldungen
/// (PROJECT_BRAIN Abschnitt 9/20) - analog zu PoiRepository fuer POIs.
class ReportRepository {
  ReportRepository({StorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  Future<List<UserReport>> loadReports() => _storage.loadReports();

  /// Speichert [report] und gibt ihn inkl. der von SQLite vergebenen id
  /// zurueck.
  Future<UserReport> addReport(UserReport report) async {
    final id = await _storage.insertReport(report);
    return report.copyWith(id: id);
  }
}
