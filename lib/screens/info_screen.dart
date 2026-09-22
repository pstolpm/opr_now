import 'package:flutter/material.dart';

/// "Über"-Seite: Projektbeschreibung, Datenquellen/Attribution und FAQ.
///
/// Inhalt mit dem Nutzer abgestimmt (Design-Überarbeitung): keine
/// Versions-/Kontaktangaben, dafür Studienkontext, Quellenangaben
/// (PROJECT_BRAIN Regel 10 / Abschnitt 37) und häufige Fragen.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Über OPR NOW')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionHeader('Projekt'),
          _ProjectDescription(),
          SizedBox(height: 24),
          _SectionHeader('Datenquellen & Attribution'),
          SizedBox(height: 4),
          _DataSources(),
          SizedBox(height: 24),
          _SectionHeader('Häufige Fragen'),
          SizedBox(height: 4),
          _Faq(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ProjectDescription extends StatelessWidget {
  const _ProjectDescription();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPR NOW ist eine mobile, standort- und kontextsensitive '
            'Geoanwendung für spontane Freizeitaktivitäten im Landkreis '
            'Ostprignitz-Ruppin. Die App verbindet den aktuellen Standort '
            'mit offenen und amtlichen Geodaten, Wetterinformationen und '
            'einem Routingdienst und schlägt darauf aufbauend passende '
            'Ziele und Routen vor. Ergänzend können Nutzer:innen eigene '
            'Beobachtungen (z. B. Wegsperrungen) erfassen und als GeoJSON '
            'exportieren.',
            style: bodyStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'Die App entsteht als Studienprojekt im Master Geoinformation '
            'an der Berliner Hochschule für Technik (BHT) im Rahmen eines '
            'GeoIT-Kurses. Sie ist ein funktionaler Prototyp (MVP) und '
            'kein fertiges kommerzielles Produkt.',
            style: bodyStyle,
          ),
        ],
      ),
    );
  }
}

class _DataSources extends StatelessWidget {
  const _DataSources();

  static const _sources = [
    _Source(
      title: 'Kartendarstellung',
      body:
          'OpenFreeMap (Stil "Liberty", MIT-Lizenz). Kartendaten: '
          '© OpenStreetMap-Mitwirkende, Kartenschema OpenMapTiles.',
    ),
    _Source(
      title: 'Sehenswürdigkeiten, Natur- und Gastronomieziele',
      body:
          'Overpass API / OpenStreetMap. © OpenStreetMap-Mitwirkende, '
          'lizenziert unter der Open Database License (ODbL).',
    ),
    _Source(
      title: 'Badestellen',
      body:
          'Amtliche Badestellendaten des Landes Brandenburg '
          '(badestellen.brandenburg.de). Geodaten: © Geobasis-DE/LGB. '
          'Fachdaten: © Ministerium für Land- und Ernährungswirtschaft, '
          'Umwelt und Verbraucherschutz Brandenburg (MLUK).',
    ),
    _Source(
      title: 'Wetter',
      body:
          'Weather data by Open-Meteo.com, lizenziert unter '
          'CC BY 4.0.',
    ),
    _Source(
      title: 'Routing',
      body:
          'Valhalla-Routingserver (openstreetmap.de, betrieben von '
          'FOSSGIS e.V.), berechnet auf Basis von OpenStreetMap-Daten.',
    ),
    _Source(
      title: 'Nutzer-Meldungen',
      body:
          'Von Nutzer:innen der App selbst erfasste Beobachtungen. '
          'Diese Daten verbleiben lokal auf dem Gerät, bis sie '
          'ausdrücklich als GeoJSON exportiert werden.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final source in _sources)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(source.body, style: textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }
}

class _Source {
  const _Source({required this.title, required this.body});

  final String title;
  final String body;
}

class _Faq extends StatelessWidget {
  const _Faq();

  static const _entries = [
    _FaqEntry(
      question: 'Was ist OPR NOW?',
      answer:
          'Eine App, die anhand von Standort, Zeitbudget, Mobilitätsart, '
          'Interessen und aktuellem Wetter passende Freizeitziele im '
          'Landkreis Ostprignitz-Ruppin vorschlägt und dorthin navigiert.',
    ),
    _FaqEntry(
      question: 'Warum benötigt die App meinen Standort?',
      answer:
          'Der Standort ist Grundlage für Entfernungen, Reisezeiten und '
          'Routenvorschläge. Ohne GPS lässt sich stattdessen einer der '
          'Demo-Standorte im Landkreis wählen, um die App vollständig ohne '
          'echten Standortzugriff zu testen.',
    ),
    _FaqEntry(
      question: 'Werden meine Standortdaten gespeichert oder weitergegeben?',
      answer:
          'Die App betreibt keinen eigenen Server und legt keine '
          'Nutzerprofile oder Bewegungsverläufe an. Der Standort wird nur '
          'an die Wetter- und Routing-Dienste übermittelt, wenn dies für '
          'die jeweilige Funktion (Wetter am Standort, Routenberechnung) '
          'notwendig ist.',
    ),
    _FaqEntry(
      question: 'Was passiert mit einer gemeldeten Beobachtung '
          '(z. B. Wegsperrung)?',
      answer:
          'Meldungen werden lokal auf dem Gerät gespeichert und auf der '
          'Karte angezeigt. Ein Export als GeoJSON-Datei ist jederzeit '
          'über die Teilen-Funktion möglich, eine automatische Übertragung '
          'an Dritte findet nicht statt.',
    ),
    _FaqEntry(
      question: 'Funktioniert die App ohne Internetverbindung?',
      answer:
          'Kartendarstellung, POI-Daten, Wetter und Routing benötigen eine '
          'Internetverbindung. Bereits geladene Meldungen und Daten '
          'bleiben lokal verfügbar; Wegsperrungen-Meldungen lassen sich '
          'auch offline erfassen und werden gespeichert.',
    ),
    _FaqEntry(
      question: 'Warum deckt die App nur Ostprignitz-Ruppin ab?',
      answer:
          'Die App ist ein Studienprojekt mit begrenztem Umfang. '
          'Ostprignitz-Ruppin wurde als überschaubarer, datenmäßig gut '
          'abgedeckter Landkreis für den Prototyp gewählt.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in _entries)
          ExpansionTile(
            title: Text(entry.question),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            expandedAlignment: Alignment.centerLeft,
            children: [
              Text(
                entry.answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _FaqEntry {
  const _FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}
