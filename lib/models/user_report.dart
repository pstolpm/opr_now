/// Fest definierte Kategorien fuer Nutzer-Meldungen (PROJECT_BRAIN
/// Abschnitt 9). Als eigene Klasse statt eines Enums, damit der
/// Kategorie-Schluessel 1:1 als String in SQLite und GeoJSON landet -
/// analog zu Poi.category.
class ReportCategory {
  ReportCategory._();

  static const wegsperrung = 'wegsperrung';
  static const schlechterWegzustand = 'schlechter_wegzustand';
  static const aussichtspunkt = 'aussichtspunkt';
  static const fahrradstaender = 'fahrradstaender';
  static const picknickplatz = 'picknickplatz';
  static const sonstiges = 'sonstiges';

  static const List<String> all = [
    wegsperrung,
    schlechterWegzustand,
    aussichtspunkt,
    fahrradstaender,
    picknickplatz,
    sonstiges,
  ];

  static const Map<String, String> labels = {
    wegsperrung: 'Weg gesperrt',
    schlechterWegzustand: 'Schlechter Wegzustand',
    aussichtspunkt: 'Schoener Aussichtspunkt',
    fahrradstaender: 'Fahrradstaender',
    picknickplatz: 'Picknickplatz',
    sonstiges: 'Sonstiger Hinweis',
  };

  static String labelFor(String category) => labels[category] ?? category;
}

/// Eine selbst erfasste Meldung (PROJECT_BRAIN Abschnitt 9/21).
///
/// [id] ist null, solange die Meldung noch nicht in SQLite gespeichert
/// wurde - die Datenbank vergibt die id selbst (AUTOINCREMENT), siehe
/// StorageService.
class UserReport {
  const UserReport({
    this.id,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.comment,
  });

  final int? id;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? comment;

  UserReport copyWith({int? id}) {
    return UserReport(
      id: id ?? this.id,
      category: category,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      comment: comment,
    );
  }

  /// Spaltenwerte fuer SQLite (StorageService). 'id' bleibt beim Insert
  /// weg, da AUTOINCREMENT die id selbst vergibt.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'comment': comment,
    };
  }

  factory UserReport.fromMap(Map<String, Object?> map) {
    return UserReport(
      id: map['id'] as int?,
      category: map['category'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      comment: map['comment'] as String?,
    );
  }

  /// Fuer die Kartendarstellung (PROJECT_BRAIN Abschnitt 9: "Die Meldung
  /// soll anschliessend auf der Karte dargestellt werden").
  ///
  /// GeoJSON-Koordinatenreihenfolge: [longitude, latitude]
  /// (PROJECT_BRAIN Abschnitt 34).
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'id': 'report:$id',
      'properties': {
        'category': category,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };
  }
}
