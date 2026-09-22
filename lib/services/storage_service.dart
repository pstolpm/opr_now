import 'package:sqflite/sqflite.dart';

import '../models/user_report.dart';

/// Lokale SQLite-Speicherung fuer selbst erfasste Meldungen (PROJECT_BRAIN
/// Abschnitt 9/18). Eine normale SQLite-Tabelle mit Latitude/Longitude
/// reicht fuer den MVP - keine raeumliche Datenbank noetig (Abschnitt 18).
///
/// Singleton, damit die Datenbankverbindung app-weit genau einmal
/// geoeffnet wird.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _dbFileName = 'opr_now.db';
  static const _reportsTable = 'user_reports';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    // Bewusst ohne das `path`-Paket: die App ist Android-only (PROJECT_BRAIN
    // Abschnitt 13), dort ist "/" als Pfadtrenner immer gueltig - ein
    // zusaetzlicher Dependency waere hier unnoetig (Regel 2/3: schlanker
    // Stack).
    final dbPath = '$dbDir/$_dbFileName';

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_reportsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            comment TEXT
          )
        ''');
      },
    );
  }

  /// Speichert [report] und gibt die von SQLite vergebene id zurueck.
  Future<int> insertReport(UserReport report) async {
    final db = await _database;
    final values = report.toMap()..remove('id');
    return db.insert(_reportsTable, values);
  }

  /// Laedt alle gespeicherten Meldungen, neueste zuerst.
  Future<List<UserReport>> loadReports() async {
    final db = await _database;
    final rows = await db.query(_reportsTable, orderBy: 'timestamp DESC');
    return rows.map(UserReport.fromMap).toList();
  }
}
