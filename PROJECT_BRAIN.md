# OPR NOW – PROJECT BRAIN

---

## 1. Projektkontext

### Hochschule und Aufgabe

Das Projekt entsteht im Studiengang **Geoinformation** im Rahmen einer Lehrveranstaltung bei **Prof. Dr. Roland Wagner**.

Die Aufgabenstellung verlangt ein eigenes Projekt zur **Geodatenhaltung und -Vernetzung in der GeoIT** mit freiem fachlichem Thema. Typische GeoIT-Funktionen und -bausteine sollen sinnvoll eingesetzt werden, unter anderem:

- thematisches Mapping
- Ortung
- gegebenenfalls mobile Datenerfassung
- Integration unterschiedlicher Geodatenquellen
- Updating von Geodaten
- gegebenenfalls unterschiedliche Geodatenmodelle
- Nutzung üblicher Geowebinfrastrukturen
- OpenStreetMap
- Overture Maps
- gegebenenfalls Google Maps APIs
- Routing
- Mobile Computing
- Location Based Apps
- möglichst neuere GeoIT-Plattformen bzw. Konzepte

Mobile, kontextsensitive oder sensorgestützte Ansätze sind fachlich höher zu bewerten als eine reine klassische Web- oder Desktopanwendung.

### Abgabe

Abgegeben werden sollen:

1. **Quellcode**
2. **ausführbarer Code**

Es ist **keine dauerhaft gehostete Produktivversion** erforderlich.

Geplantes Abgabeformat:

- vollständiges Flutter-Projekt als Quellcode
- Android-APK als ausführbare Anwendung
- ergänzend README mit Installations-, Build- und Nutzungsanleitung

---

# 2. Projektidee

## Arbeitstitel

**OPR NOW – Kontextsensitiver Geo-Explorer für spontane Ausflüge in Ostprignitz-Ruppin**

Kurzname:

**OPR NOW**

Untersuchungs- und Anwendungsraum:

**Landkreis Ostprignitz-Ruppin (OPR), Brandenburg**

---

# 3. Leitidee

OPR NOW soll **kein gewöhnlicher digitaler Reiseführer** und keine bloße Karte mit Sehenswürdigkeiten sein.

Die zentrale Fragestellung der App lautet:

> **Was kann ich von meinem aktuellen Standort aus jetzt sinnvoll unternehmen?**

Die Anwendung soll den aktuellen räumlichen und situativen Kontext des Nutzers berücksichtigen und daraus geeignete Ziele bzw. Touren ableiten.

Mögliche Kontextinformationen:

- aktuelle GPS-Position
- verfügbare Zeit
- gewünschte Fortbewegungsart
- Interessen
- Entfernung zu Zielen
- aktuelle Uhrzeit
- Wetter
- Eigenschaften eines POI
- Erreichbarkeit über das Wegenetz

Beispiel:

```text
Standort:
Neuruppin

Verfügbare Zeit:
120 Minuten

Fortbewegung:
Fahrrad

Interessen:
Natur + Wasser

Wetter:
trocken, warm

Ergebnis:
geeignete POIs + sinnvolle Route
```

Die App verarbeitet also Geodaten aktiv und stellt sie nicht nur dar.

---

# 4. Abgrenzung zu einer klassischen Tourismus-App

Bereits bekannte Standardfunktionen wie

- Sehenswürdigkeiten anzeigen
- Veranstaltungskalender
- Restaurants anzeigen
- digitale Tickets
- Tischreservierungen
- statische Tourenvorschläge

reichen allein nicht als innovative Projektidee aus.

Solche Funktionen dürfen später ergänzend vorkommen, sind aber **nicht der fachliche Kern**.

Der GeoIT-Kern von OPR NOW ist:

> **Standortbezogene, kontextsensitive Auswahl, Kombination und Navigation zu touristisch bzw. freizeitbezogen relevanten Geoobjekten auf Grundlage mehrerer Geodatenquellen.**

---

# 5. Fachliche Kernfunktionen

## 5.1 Live-Karte

Darstellung einer interaktiven Karte mit unterschiedlichen thematischen Layern.

Mögliche Kategorien:

- Sehenswürdigkeiten
- Museen
- Schlösser
- Aussichtspunkte
- Naturziele
- Badestellen
- Gastronomie
- Picknickplätze
- Toiletten
- Fahrradverleih
- Camping
- touristische Attraktionen
- selbst erfasste Meldungen

GeoIT-Bezug:

- thematisches Mapping
- Layerverwaltung
- Vektor-/GeoJSON-Daten
- räumliche Visualisierung

---

## 5.2 Standortbestimmung

Die App soll die aktuelle Position des Nutzers über das Smartphone-GPS ermitteln.

Funktionen:

- Standortberechtigung abfragen
- aktuelle Position bestimmen
- Position auf der Karte anzeigen
- optional fortlaufende Positionsupdates
- Entfernung zu POIs berechnen

GeoIT-Bezug:

- Mobile Computing
- Location Based App
- GNSS/GPS
- räumlicher Kontext

---

## 5.3 Kontextbasierte Funktion „Was kann ich jetzt machen?“

Dies ist eine der wichtigsten Funktionen des Projekts.

Der Nutzer gibt beispielsweise an:

- verfügbares Zeitbudget
- Mobilitätsart
- Interessen

Die App ergänzt automatisch:

- aktuelle Position
- Wetter
- Entfernung
- mögliche Reisezeit
- POI-Eigenschaften

Anschließend werden passende Ziele ausgewählt bzw. priorisiert.

Beispiel:

```text
Nutzer:
- 90 Minuten Zeit
- Fahrrad
- Natur + Kultur

System:
- aktueller Standort
- trockenes Wetter
- Entfernung der POIs
- geschätzte Fahrzeit

Ausgabe:
- mehrere geeignete Ziele
- Distanz
- Reisezeit
- Route
```

---

# 6. Context Engine

Die **Context Engine** ist das fachliche Herzstück der App.

Sie führt unterschiedliche Datenquellen und Nutzereingaben zusammen.

Grundprinzip:

```text
GPS-Position
      +
verfügbare Zeit
      +
Fortbewegungsart
      +
Interessen
      +
Wetter
      +
POIs
      +
Routinginformationen
      ↓
Context Engine
      ↓
geeignete Ziele
      ↓
Route / Tour
```

Die Context Engine soll zunächst **regelbasiert und transparent** umgesetzt werden.

Es ist nicht notwendig, Machine Learning einzusetzen.

Eine nachvollziehbare Entscheidungslogik ist für das Uni-Projekt fachlich sinnvoller als eine unnötig komplexe KI.

### Beispiel für eine einfache Bewertungslogik

Ein POI kann einen Score erhalten.

Beispielhafte Gewichtung:

```text
Score =
0,40 * DistanzScore
+ 0,30 * InteressenScore
+ 0,20 * WetterScore
+ 0,10 * weiterer KontextScore
```

Diese Gewichtung ist zunächst nur ein Entwurfswert.

Vor finaler Implementierung muss geprüft werden, ob die Gewichtung fachlich plausibel ist.

### Beispielhafte Regeln

```text
wenn POI = Outdoor
und starker Regen
→ WetterScore reduzieren
```

```text
wenn POI = Museum
und schlechtes Wetter
→ WetterScore erhöhen
```

```text
wenn geschätzte Hin- und Rückreisezeit > verfügbares Zeitbudget
→ POI ausschließen
```

```text
wenn Interesse des Nutzers mit POI-Kategorie übereinstimmt
→ InteressenScore erhöhen
```

Die Logik muss im Quellcode dokumentiert und in der Projektdokumentation nachvollziehbar erläutert werden.

---

# 7. Routing

Die App soll Routing zwischen der aktuellen Position und einem ausgewählten Ziel ermöglichen.

Mindestens:

- Fußrouting
- Fahrradrouting

Optional:

- mehrere Zwischenziele
- Rundtour
- ÖPNV
- multimodales Routing

Geplanter Ablauf:

```text
GPS-Position
     ↓
Startpunkt

POI
     ↓
Zielpunkt

Routing API
     ↓
Routengeometrie

GeoJSON / Koordinaten
     ↓
MapLibre

Route auf Karte
```

## Geplante Routing-Technologie

**Valhalla**

Begründung:

- Open Source
- OSM-basierte Routing-Engine
- für Fuß- und Fahrradrouting geeignet
- REST-API
- gute fachliche Passung zu einem offenen GeoIT-Projekt

### Wichtige Regel

Die App soll **keinen eigenen Routingalgorithmus von Grund auf implementieren**.

Der fachliche Schwerpunkt liegt auf Integration und Nutzung räumlicher Dienste, nicht auf der Neuerfindung eines Routinggraphen.

---

# 8. Geofencing / Location Trigger

Eine zentrale mobile GeoIT-Funktion soll ein einfacher Geofence bzw. standortabhängiger Trigger sein.

Beispiel:

```text
Distanz Nutzer ↔ Ziel < 75 m
```

Dann kann die App auslösen:

```text
Du hast dein Ziel erreicht.
```

oder:

```text
GeoSpot entdeckt.
```

oder:

```text
Noch 80 m bis zum Aussichtspunkt.
```

Technisch reicht für den MVP eine selbst implementierte Distanzprüfung auf Basis laufender Standortupdates.

Ein systemweites Background-Geofencing ist **nicht zwingend erforderlich**.

GeoIT-Bezug:

- Ortung
- räumlicher Kontext
- Mobile Computing
- Location Based Services

---

# 9. Mobile Geodatenerfassung

Der Nutzer soll mindestens einen eigenen räumlichen Datensatz erfassen können.

Mögliche Meldungstypen:

- Weg gesperrt
- schlechter Wegzustand
- schöner Aussichtspunkt
- Fahrradständer
- Picknickplatz
- sonstiger Hinweis

Mindestens zu speichernde Attribute:

```text
id
category
latitude
longitude
timestamp
comment
```

Optional:

```text
photoPath
accuracy
source
```

Beispiel:

```text
ID: 42
Kategorie: Wegsperrung
Latitude: 52.9254
Longitude: 12.8031
Zeitpunkt: 2026-09-16T15:42:00
Kommentar: Weg derzeit nicht passierbar
```

Die Meldung soll anschließend auf der Karte dargestellt werden.

---

# 10. GeoJSON-Export

Selbst erfasste Geodaten sollen als **GeoJSON** exportierbar sein.

Beispiel:

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [12.8031, 52.9254]
  },
  "properties": {
    "category": "Wegsperrung",
    "timestamp": "2026-09-16T15:42:00",
    "comment": "Weg derzeit nicht passierbar"
  }
}
```

Damit wird die komplette GeoIT-Prozesskette sichtbar:

```text
mobile Erfassung
→ Koordinate
→ Datenmodell
→ lokale Speicherung
→ Kartendarstellung
→ GeoJSON-Export
```

---

# 11. Datenquellen

Die App soll bewusst **mehrere unterschiedliche Datenquellen und Datenmodelle integrieren**.

## 11.1 OpenStreetMap

Hauptanwendungsfälle:

- touristische POIs
- Museen
- Sehenswürdigkeiten
- Aussichtspunkte
- Gastronomie
- Picknickplätze
- Toiletten
- Camping
- Freizeitobjekte
- eventuell Routinggrundlage

Geplante Schnittstelle für POI-Abfragen:

**Overpass API**

Beispielhafte OSM-Tags:

```text
tourism=*
amenity=cafe
amenity=restaurant
amenity=toilets
leisure=*
historic=*
natural=*
```

### Regel für Overpass

Keine permanenten oder extrem großen Abfragen.

Stattdessen:

- räumlich auf OPR oder einen sinnvollen Suchradius begrenzen
- Ergebnisse cachen
- nicht bei jeder Kartenbewegung erneut laden
- Fehler und API-Ausfälle abfangen

---

## 11.2 Overture Maps

Overture Maps soll nach Möglichkeit bewusst integriert werden, da es explizit zur Aufgabenstellung passt.

Interessante Themes:

- Places
- Transportation
- Buildings
- Divisions
- Addresses

Für den MVP besonders relevant:

**Overture Places**

Möglicher ETL-Workflow:

```text
Overture Places
      ↓
räumlicher Filter auf OPR / Bounding Box
      ↓
Extraktion
      ↓
Transformation
      ↓
GeoJSON
      ↓
lokales Asset der Flutter-App
```

Für einen vorbereitenden ETL-Schritt darf beispielsweise Python oder DuckDB verwendet werden.

Wichtig:

Die mobile App selbst muss nicht den vollständigen Overture-Datensatz online verarbeiten.

Eine vorbereitete räumliche Teilmenge ist ausdrücklich sinnvoll.

---

## 11.3 Wetter

Geplante Wetterquelle:

**Open-Meteo**

Relevante Variablen:

- Temperatur
- Niederschlag
- Niederschlagswahrscheinlichkeit
- Wind
- Bewölkung
- gegebenenfalls Sichtweite

Nutzung:

```text
GPS-Koordinate
      ↓
Wetter-API
      ↓
aktueller Kontext
      ↓
Context Engine
```

Beispiel:

```text
Outdoorziel + Regen
→ geringere Eignung
```

```text
Museum + Regen
→ höhere Eignung
```

---

## 11.4 Offizielle Badestellen Brandenburg

Als besonders regional passende Datenquelle sollen nach Möglichkeit offizielle Badestellendaten des Landes Brandenburg verwendet werden.

Möglicher Workflow:

```text
offene Badestellendaten
      ↓
Filter auf OPR
      ↓
Transformation
      ↓
GeoJSON / lokale Datendatei
      ↓
App
```

Kombinationsmöglichkeit:

```text
Badestelle
+
GPS
+
Wetter
+
Routing
=
standortbezogene Badeempfehlung
```

Diese Datenquelle ist fachlich besonders interessant, weil sie OSM um einen amtlichen Datensatz ergänzt.

---

## 11.5 VBB – optional

VBB-Daten sind **keine MVP-Anforderung**.

Optional können später eingebunden werden:

- GTFS
- GTFS-Realtime

Mögliche Funktion:

```text
Fahrrad:
18 Minuten

ÖPNV:
Bus + Fußweg
```

### Wichtige Regel

GTFS und insbesondere Echtzeit-ÖPNV dürfen erst umgesetzt werden, wenn der MVP stabil funktioniert.

---

# 12. Aktualität und Updating

Die Aufgabenstellung erwähnt ausdrücklich das Updating von Geodaten.

Dieses Projekt erfüllt den Punkt durch eine Kombination aus:

- aktuellen API-Abfragen
- aktualisierbaren externen Geodaten
- lokalen Cache-Daten
- eigener mobiler Erfassung

Mögliche Aktualisierungslogik:

```text
Open-Meteo
→ bei Bedarf aktuell abfragen

OSM / Overpass
→ zeitweise aktualisieren und cachen

lokale Overture-Teilmenge
→ über ETL-Prozess austauschbar

Badestellendaten
→ neue Quelldatei importierbar

Nutzererfassung
→ direkt lokal aktualisiert
```

---

# 13. Technologiestack

## Hauptframework

**Flutter**

## Hauptprogrammiersprache

**Dart**

## Zielplattform

Primär:

**Android**

Begründung:

- mobile Location Based App
- direkter Zugriff auf Standortdienste
- APK kann als ausführbarer Code abgegeben werden
- keine Hosting-Infrastruktur nötig
- gute Trennung zwischen UI, Datenlogik und Services

---

# 14. Entwicklungsumgebung

Empfohlene Kombination:

## Visual Studio Code

Primäre Entwicklungsumgebung.

Benötigt:

- Flutter Extension
- Dart Extension

## Android Studio

Vor allem für:

- Android SDK
- Emulator
- Build Tools
- Geräteverwaltung

Die eigentliche Programmierung darf überwiegend in VS Code erfolgen.

---

# 15. Kartenframework

Geplant:

**MapLibre**

MapLibre ist gegenüber einer primären Google-Maps-Lösung zu bevorzugen.

Gründe:

- Open-Source-Ansatz
- gute Kombination mit offenen Geodaten
- Darstellung eigener Layer
- GeoJSON-Unterstützung
- Punkte, Linien und Polygone
- thematische Symbolisierung
- gute fachliche Passung zur Geoinformation

MapLibre übernimmt die Kartendarstellung.

---

# 16. Standortbibliothek

Geplant:

**geolocator**

Aufgaben:

- Berechtigungen
- aktuelle GPS-Position
- Positionsupdates
- Entfernungen
- gegebenenfalls Genauigkeitsinformationen

---

# 17. HTTP / API-Kommunikation

Vorgesehen:

- Dart `http`
- oder `dio`

Nur **eine** der beiden Bibliotheken als primäre HTTP-Schicht verwenden.

Nicht unnötig beide parallel einführen.

Die endgültige Wahl soll früh im Projekt getroffen und anschließend beibehalten werden.

---

# 18. Lokale Speicherung

Für selbst erfasste Meldungen und gegebenenfalls Cache-Daten:

**SQLite**

Mögliche Flutter-Implementierung:

- `sqflite`

Alternative leichte Speicherung darf geprüft werden.

Für räumliche Nutzerobjekte reicht zunächst eine normale SQLite-Tabelle mit Latitude und Longitude.

Eine vollständige räumliche Datenbank ist für den MVP nicht notwendig.

---

# 19. Geplante Systemarchitektur

```text
                     Smartphone
                         │
            ┌────────────┴────────────┐
            │                         │
           GPS                  Nutzereingaben
            │                  Zeit / Interesse
            │                    Mobilität
            └────────────┬────────────┘
                         │
                   Context Engine
                         │
       ┌─────────────────┼──────────────────┐
       │                 │                  │
      OSM            Open-Meteo       weitere Daten
    Overpass                            Overture
       │                              Badestellen
       │                 │                  │
       └─────────────────┼──────────────────┘
                         │
                    POI-Auswahl
                         │
                       Routing
                         │
                      Valhalla
                         │
                  Routengeometrie
                         │
                      MapLibre
                         │
                  Kartenvisualisierung
```

Zusätzlich:

```text
Nutzer
  ↓
Meldung erfassen
  ↓
SQLite
  ↓
Kartenlayer
  ↓
GeoJSON-Export
```

---

# 20. Empfohlene Softwarearchitektur innerhalb von Flutter

Keine monolithische `main.dart`.

Empfohlene Struktur:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
│
├── models/
│   ├── poi.dart
│   ├── user_report.dart
│   ├── weather_context.dart
│   ├── route_result.dart
│   └── recommendation.dart
│
├── services/
│   ├── location_service.dart
│   ├── weather_service.dart
│   ├── overpass_service.dart
│   ├── routing_service.dart
│   ├── storage_service.dart
│   └── export_service.dart
│
├── repositories/
│   ├── poi_repository.dart
│   └── report_repository.dart
│
├── logic/
│   ├── context_engine.dart
│   ├── recommendation_engine.dart
│   └── geofence_logic.dart
│
├── screens/
│   ├── map_screen.dart
│   ├── discover_screen.dart
│   ├── poi_detail_screen.dart
│   ├── report_screen.dart
│   └── settings_screen.dart
│
├── widgets/
│   ├── poi_card.dart
│   ├── category_filter.dart
│   ├── context_selector.dart
│   └── map_controls.dart
│
└── utils/
    ├── constants.dart
    ├── geo_utils.dart
    └── formatters.dart
```

Diese Struktur ist ein Ausgangspunkt.

Nicht für jede Kleinigkeit eine zusätzliche Abstraktionsschicht erzeugen.

---

# 21. Zentrale Datenmodelle

## POI

Beispiel:

```dart
class Poi {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String source;
  final Map<String, dynamic> properties;
}
```

Sinnvolle Felder:

```text
id
name
latitude
longitude
category
source
properties
```

Optionale Felder:

```text
openingHours
description
website
indoorOutdoor
```

---

## UserReport

```text
id
category
latitude
longitude
timestamp
comment
photoPath
```

---

## WeatherContext

```text
temperature
precipitation
precipitationProbability
windSpeed
cloudCover
timestamp
```

---

## Recommendation

```text
poi
distance
travelTime
overallScore
distanceScore
interestScore
weatherScore
reason
```

Der Nutzer soll möglichst nachvollziehen können, warum ein Ziel empfohlen wird.

---

# 22. Mindestumfang / MVP

Der MVP ist verbindlich wichtiger als zusätzliche Features.

Folgende Funktionen sollen priorisiert werden:

1. Flutter-App startet zuverlässig
2. MapLibre-Karte wird angezeigt
3. Kartenausschnitt OPR
4. GPS-Position kann ermittelt werden
5. aktueller Standort wird auf der Karte angezeigt
6. mehrere POI-Kategorien werden dargestellt
7. mindestens zwei unterschiedliche externe Geodatenquellen werden integriert
8. Wetterdaten werden abgerufen
9. Context Engine erzeugt kontextabhängige Auswahl
10. Fuß- oder Fahrradrouting funktioniert
11. Route wird auf der Karte dargestellt
12. Geofence bzw. Distanztrigger funktioniert
13. Nutzer kann ein Geoobjekt erfassen
14. Erfassung wird lokal gespeichert
15. Erfassung erscheint auf der Karte
16. erfasste Daten können als GeoJSON exportiert werden
17. Demo-Standort-Modus existiert
18. Release-APK kann gebaut werden

Wenn dieser Umfang stabil funktioniert, ist das Projekt fachlich vollständig genug.

---

# 23. Erweiterungen nach dem MVP

Nur implementieren, wenn der MVP stabil ist.

Priorität ungefähr:

## Erweiterung 1 – Gerätesensoren

- Kompass
- Heading
- eventuell Bewegungssensoren

Mögliche Funktion:

Richtungspfeil zum Ziel.

---

## Erweiterung 2 – automatische Rundtour

Mehrere POIs werden zu einer sinnvollen Tour kombiniert.

Beispiel:

```text
Start
→ Schloss
→ Aussichtspunkt
→ Café
→ Start
```

**Status: umgesetzt** (vorgezogen nach der Design-Überarbeitung, auf ausdrücklichen Nutzerwunsch, vor Phase 11–13). Implementiert als regelbasierter Greedy-Algorithmus (keine KI/ML, konsistent mit Abschnitt 6 und 24) in `lib/logic/tour_planner.dart` (`TourPlanner`): von der aktuellen Position aus wird über die Context Engine der bestbewertete, noch nicht besuchte POI gesucht, der – inklusive Rückweg zum ursprünglichen Startpunkt – noch ins Zeitbudget passt; Wiederholung, bis maximal 4 Stopps erreicht sind, kein POI mehr passt oder keine POIs mehr übrig sind.

Mit dem Nutzer abgestimmte Eckpunkte:

- Rundtour führt immer mit Rückweg zum Start zurück (kein offenes Ende)
- maximal 4 Stopps pro Rundtour
- Einstieg über einen Modus-Umschalter ("Einzelziel"/"Rundtour") im bestehenden "Entdecken"-Screen (`lib/screens/discover_screen.dart`)
- der Geofence aktiviert bei Ankunft automatisch das nächste Ziel der Kette (inkl. Rückweg), bis die Rundtour abgeschlossen ist (`lib/screens/map_screen.dart`, `_tourQueue`/`_checkGeofence`)

Die tatsächliche Route je Etappe wird erst beim Start der Tour über Valhalla berechnet (`lib/models/tour_route_result.dart`).

---

## Erweiterung 3 – Badestellenlogik

Kombination aus:

- Wetter
- Entfernung
- Routing
- amtlichen Badestellen

---

## Erweiterung 4 – Offline-Fähigkeit

Möglichkeiten:

- lokale POIs
- Cache
- gegebenenfalls Offline-Karten

Offline-Karten sind optional und dürfen den MVP nicht gefährden.

---

## Erweiterung 5 – VBB

Integration von:

- GTFS
- optional GTFS-Realtime

---

## Erweiterung 6 – GeoStories

Standortbezogene Informationen oder kleine Geschichten.

Beispiel:

```text
Nutzer erreicht historischen Ort
→ standortbezogene Information öffnet sich
```

---

## Erweiterung 7 – AR-artige Navigation

Ein einfacher Richtungspfeil oder Kamera-Overlay kann geprüft werden.

Eine vollständige AR-Plattform ist nicht notwendig.

---

# 24. Bewusst nicht als Kern vorgesehen

Folgende Funktionen sind **nicht Teil des MVP**:

- vollständiger Veranstaltungskalender
- Ticketshop
- Zahlungsabwicklung
- Tischreservierungen
- Hotelbuchung
- Benutzerkonten
- Social Network
- Chat
- eigenes komplexes Backend
- eigener Routingalgorithmus
- vollständige SLAM-Implementierung
- autonome Navigation
- Machine-Learning-Modell nur um „KI“ zu zeigen

Diese Funktionen erzeugen viel Aufwand, ohne den GeoIT-Kern ausreichend zu verbessern.

---

# 25. Warum kein vollständiges SLAM?

SLAM ist für den konkreten Anwendungsfall nicht zwingend fachlich gerechtfertigt.

OPR NOW ist primär:

- Outdoor
- GNSS-basiert
- touristisch
- netzwerk- und POI-orientiert

Eine künstliche SLAM-Funktion würde das Projekt unnötig verkomplizieren.

Besser ist eine sauber umgesetzte Kombination aus:

- GPS
- Geofencing
- Routing
- mobilen Sensoren
- Kontextdaten
- Echtzeit-APIs
- Geodatenintegration

---

# 26. Demo-Standort-Modus

Ein Demo-Modus ist **verbindlich einzuplanen**.

Grund:

Die App wird voraussichtlich nicht direkt in OPR präsentiert.

Der Nutzer muss zwischen echtem GPS und simulierten Demo-Standorten wechseln können.

Beispiel:

```text
Standortmodus

○ Echtes GPS
○ Demo – Neuruppin
○ Demo – Rheinsberg
○ Demo – eigener Testpunkt
```

Der Demo-Modus muss in der UI klar als Simulation gekennzeichnet sein.

Ziel:

Alle standortbezogenen Funktionen müssen auch in Hochschule, Zuhause oder Emulator vorführbar sein.

---

# 27. Beispiel für einen vollständigen Demo-Workflow

```text
1. App starten

2. Demo-Standort Neuruppin aktivieren

3. Karte springt nach Neuruppin

4. Nutzer wählt:
   - 120 Minuten
   - Fahrrad
   - Natur + Wasser

5. Wetter wird geladen

6. verfügbare POIs werden ausgewertet

7. App zeigt geeignete Ziele

8. Nutzer wählt Ziel

9. Fahrradrouting wird berechnet

10. Route erscheint auf Karte

11. Demo-Position wird in Richtung Ziel verschoben

12. Geofence löst aus

13. Nutzer meldet zusätzlich eine Wegsperrung

14. Wegsperrung erscheint auf Karte

15. Meldung wird als GeoJSON exportiert
```

Dieser Workflow sollte möglichst vollständig demonstrierbar sein.

---

# 28. Entwicklungsphasen

## Phase 0 – Projektdefinition

Erstellen bzw. finalisieren:

- Projektskizze
- Funktionsumfang
- Datenquellen
- Tech-Stack
- Architektur
- MVP

Keine zusätzliche Funktion beginnen, bevor der Umfang klar ist.

---

## Phase 1 – Flutter-Grundgerüst

Ziel:

```text
Flutter-Projekt existiert
→ Android-App startet
```

Aufgaben:

- Flutter installieren
- Android SDK einrichten
- Emulator einrichten
- Projekt erzeugen
- Git-Repository initialisieren
- Basisordner anlegen

---

## Phase 2 – Karte

Ziel:

```text
App startet
→ MapLibre-Karte erscheint
→ OPR ist sichtbar
```

Noch keine komplexen API-Integrationen.

---

## Phase 3 – GPS

Ziel:

```text
Berechtigung
→ Standort
→ Marker
```

Zusätzlich:

- Fehlerbehandlung
- GPS nicht verfügbar
- Berechtigung verweigert

---

## Phase 4 – lokale Test-POIs

Vor externen APIs zunächst eine kleine lokale GeoJSON-Datei verwenden.

Beispiel:

```text
assets/data/test_pois.geojson
```

Etwa 10–20 Testobjekte.

Ziel:

- Layerdarstellung
- Kategorien
- Popup / Detailansicht
- POI-Auswahl

Erst wenn dies funktioniert, externe Daten anbinden.

---

## Phase 5 – externe Datenquellen

Reihenfolge:

1. Open-Meteo
2. OSM / Overpass
3. Badestellen
4. Overture
5. weitere Quellen nur bei Bedarf

Jede Quelle separat implementieren und testen.

---

## Phase 6 – Routing

Ziel:

```text
Start + Ziel
→ Routing Request
→ Routengeometrie
→ Karte
```

Zuerst nur ein Verkehrsmittel.

Danach zweites Profil ergänzen.

---

## Phase 7 – Context Engine

Ziel:

POIs werden nicht nur angezeigt, sondern bewertet.

Erste Version bewusst einfach halten.

Anschließend schrittweise verbessern.

---

## Phase 8 – mobile Datenerfassung

Implementieren:

- Kategorie
- Kommentar
- aktuelle Koordinate
- Timestamp
- lokale Speicherung
- Kartendarstellung

---

## Phase 9 – GeoJSON-Export

Aus lokalen Meldungen:

```text
SQLite
→ GeoJSON
→ Datei
```

---

## Phase 10 – Geofence

Implementieren:

```text
aktuelle Position
→ Distanz Ziel
→ Schwellenwert
→ Trigger
```

---

## Phase 11 – Demo-Modus

Demo-Standorte integrieren.

Alle Kernfunktionen damit testen.

---

## Phase 12 – Stabilisierung

- Fehlerbehandlung
- Loading States
- fehlendes Internet
- API-Ausfall
- GPS-Ausfall
- leere Ergebnisse
- fehlerhafte API-Daten
- ungültige Geometrien

---

## Phase 13 – Release

Erstellen:

```bash
flutter build apk --release
```

Erwartetes Ergebnis:

```text
app-release.apk
```

Anschließend auf einem echten Android-Gerät testen.

---

# 29. UI-Grundstruktur

Empfohlene Hauptbereiche:

## Karte

Zentrale Kartenansicht.

Funktionen:

- eigener Standort
- POIs
- Route
- Nutzer-Meldungen
- Layer / Kategorien
- Zentrieren auf Standort

---

## Entdecken / „Jetzt“

Kontextbasierte Eingabe:

```text
Wie viel Zeit hast du?

Wie möchtest du dich bewegen?

Was interessiert dich?
```

Danach Empfehlungen.

---

## POI-Details

Mögliche Inhalte:

- Name
- Kategorie
- Entfernung
- geschätzte Reisezeit
- Quelle
- Wettertauglichkeit
- Routing starten

---

## Melden

Formular für mobile Geodatenerfassung.

---

## Einstellungen

Mindestens:

- GPS oder Demo-Modus
- Demo-Standort
- gegebenenfalls Datenaktualisierung

---

# 30. Fachlicher GeoIT-Nachweis

Das Projekt soll in Dokumentation und Präsentation klar zeigen, welche Aufgabenstellung durch welche Funktion erfüllt wird.

| Anforderung | Umsetzung in OPR NOW |
|---|---|
| Thematisches Mapping | POIs, Badestellen, Nutzer-Meldungen |
| Ortung | Smartphone-GPS |
| Erfassung | mobile Nutzer-Meldung |
| Integration | OSM, Overture, Open-Meteo, amtliche Daten |
| Updating | APIs, aktualisierbare Quelldaten, Nutzererfassung |
| unterschiedliche Datenmodelle | OSM, Overture, CSV/GeoJSON, SQLite |
| Geowebinfrastruktur | REST APIs, OSM/Overpass |
| Routing | Valhalla |
| Mobile Computing | Flutter-Android-App |
| Location Based App | zentraler Projektansatz |
| Sensor-/Kontextbezug | GPS, optional Heading, Live-Wetter |
| Geodatenhaltung | SQLite + lokale GeoJSON-Daten |
| Geodatenvernetzung | Context Engine + APIs + Routing |

---

# 31. Kernaussage für Projektskizze und Präsentation

Die zentrale Beschreibung des Projekts lautet sinngemäß:

> OPR NOW ist eine mobile, standort- und kontextsensitive Geoanwendung für spontane Freizeitaktivitäten im Landkreis Ostprignitz-Ruppin. Die Anwendung verbindet den aktuellen Standort eines Nutzers mit offenen und amtlichen Geodaten, Wetterinformationen und Routingdiensten. Auf dieser Grundlage werden situationsabhängig geeignete Ziele ausgewählt und navigierbar gemacht. Ergänzend ermöglicht die App die mobile Erfassung eigener Geoobjekte und deren Export als GeoJSON.

Diese Beschreibung darf sprachlich angepasst werden, der fachliche Inhalt soll erhalten bleiben.

---

# 32. KI-gestützte Entwicklung

Das Projekt soll ausdrücklich **mit Unterstützung von KI entwickelt werden**.

Die KI ist Entwicklungswerkzeug, aber fachliche und technische Entscheidungen müssen nachvollziehbar bleiben.

Der Nutzer muss den Code verstehen und erklären können.

## Regeln für Coding Agents

### Regel 1 – Dieses Dokument ist verbindlich

Vor größeren Änderungen:

1. PROJECT_BRAIN lesen
2. vorhandenen Code prüfen
3. aktuelle Architektur berücksichtigen
4. erst danach Änderungen vornehmen

---

### Regel 2 – Keine eigenmächtigen Stack-Wechsel

Nicht ohne ausdrücklichen Grund ersetzen:

```text
Flutter
Dart
MapLibre
geolocator
Valhalla
OpenStreetMap / Overpass
Open-Meteo
SQLite
GeoJSON
```

Wenn ein technischer Bestandteil objektiv ungeeignet oder nicht mehr kompatibel ist:

- Problem benennen
- Alternative erläutern
- Auswirkungen nennen
- erst dann Änderung empfehlen

---

### Regel 3 – Kein unnötiges Backend

Standardannahme:

**Die App funktioniert ohne eigenes Backend.**

Keinen Server, Firebase, Supabase, Node.js-Server oder Cloud-Backend einführen, nur weil es bequem erscheint.

Ein Backend darf nur ergänzt werden, wenn eine konkrete Funktion es wirklich erfordert.

---

### Regel 4 – MVP vor Erweiterungen

Nie optionale Funktionen priorisieren, solange Kernfunktionen instabil oder unvollständig sind.

Reihenfolge:

```text
funktionierend
→ robust
→ verständlich
→ erweitert
```

Nicht:

```text
viele Features
→ technische Schulden
→ unfertiger MVP
```

---

### Regel 5 – Änderungen klein halten

Bevorzugt:

- kleine nachvollziehbare Commits
- einzelne Features
- einzelne Services
- testbare Zwischenschritte

Keine riesigen Komplettumbauten ohne Notwendigkeit.

---

### Regel 6 – Nutzer muss Code verstehen können

Bei wichtigen Implementierungen erklären:

- was wurde geändert?
- warum?
- welche Datei?
- welche Abhängigkeit?
- wie funktioniert die GeoIT-Logik?
- wie lässt sich die Funktion testen?

Keine Black-Box-Lösungen erzeugen.

---

### Regel 7 – Keine erfundenen APIs oder Bibliotheken

Vor Verwendung prüfen:

- Paket existiert
- Paket ist mit aktueller Flutter-Version kompatibel
- API existiert
- Endpoint ist dokumentiert
- Nutzungsbedingungen passen zum studentischen Projekt

Keine Parameter, Endpoints oder Paketnamen halluzinieren.

---

### Regel 8 – API-Fehler berücksichtigen

Jeder externe Dienst kann ausfallen.

Deshalb:

- Timeouts
- Fehlerbehandlung
- leere Ergebnisse
- verständliche Fehlermeldungen
- gegebenenfalls Cache/Fallback

einplanen.

---

### Regel 9 – Secrets nicht committen

Keine API-Schlüssel direkt in Quellcode oder Git speichern.

Falls später API-Keys benötigt werden:

- lokale Konfiguration
- `.env`
- entsprechende Datei in `.gitignore`
- Beispielkonfiguration ohne echte Secrets

Open-Meteo und offene OSM-Dienste möglichst ohne unnötige Secrets verwenden.

---

### Regel 10 – Quellen kenntlich machen

POIs sollen nach Möglichkeit ihre Quelle behalten.

Beispiel:

```text
source = "OSM"
source = "Overture"
source = "Brandenburg"
source = "User"
```

Dies hilft bei:

- Debugging
- Attribution
- Dokumentation
- Datenvergleich

---

# 33. Datenqualität und Dubletten

Da mehrere Quellen integriert werden, können dieselben Orte mehrfach vorkommen.

Beispiel:

```text
Schloss Rheinsberg aus OSM
+
Schloss Rheinsberg aus Overture
```

Für den MVP reicht eine einfache Strategie.

Mögliche Prüfung:

- ähnliche Namen
- geringe räumliche Distanz
- ähnliche Kategorie

Dublettenbereinigung ist ein mögliches erweitertes GeoIT-Thema, aber kein Muss für die erste Version.

Quellen dürfen zunächst getrennt dargestellt werden, wenn dies transparent dokumentiert wird.

---

# 34. Koordinaten und Geometrien

Für mobile Web-/App-Schnittstellen wird in der Regel mit WGS84-Koordinaten gearbeitet.

GeoJSON verwendet Koordinaten in der Reihenfolge:

```text
Longitude, Latitude
```

also:

```json
[12.8031, 52.9254]
```

Nicht vertauschen.

Bei Distanzberechnungen muss berücksichtigt werden, ob:

- eine Bibliothek geodätische Distanz berechnet
- oder lediglich kartesische Koordinaten verwendet

Keine naive euklidische Distanz direkt auf Gradkoordinaten für größere Distanzen verwenden.

---

# 35. Performance

Vermeiden:

- riesige GeoJSON-Dateien
- komplette deutschlandweite POI-Datensätze
- Overpass-Abfrage bei jeder Kartenbewegung
- tausende Marker als individuelle Flutter-Widgets
- unnötige API-Aufrufe

Bevorzugen:

- Bounding Box / Radius
- räumliche Filterung
- Caching
- Clustering, falls notwendig
- kleine Datenmengen im MVP

---

# 36. Datenschutz

Die App benötigt Standortzugriff.

Grundprinzip:

- nur Standortdaten verwenden, die für Funktion notwendig sind
- Position standardmäßig nicht an einen eigenen Server senden
- keine Nutzerprofile
- keine unnötige Speicherung von Bewegungsverläufen

Wenn Standortdaten an Routing- oder Wetterdienste übermittelt werden, muss dies in der Dokumentation transparent benannt werden.

---

# 37. Attribution und Lizenzen

Vor der finalen Abgabe müssen die Lizenz- und Attributionsbedingungen aller Daten- und Kartendienste geprüft werden.

Besonders:

- OpenStreetMap
- verwendeter Kartenstil / Tile Provider
- Overture Maps
- amtliche Brandenburg-Daten
- Routingdienst
- Wetterdienst

Attribution soll sichtbar bzw. entsprechend den jeweiligen Bedingungen umgesetzt werden.

---

# 38. Tests

Mindestens folgende Szenarien prüfen.

## Standort

- Berechtigung erlaubt
- Berechtigung verweigert
- GPS deaktiviert
- Standort verfügbar
- Demo-Modus aktiv

## Karte

- Karte lädt
- POIs erscheinen
- Kategorien funktionieren
- Route erscheint

## APIs

- erfolgreiche Antwort
- Timeout
- keine Ergebnisse
- ungültige Antwort

## Context Engine

- passende Interessen
- unpassende Interessen
- sehr kleines Zeitbudget
- schlechtes Wetter
- keine erreichbaren Ziele

## Routing

- Fuß
- Fahrrad
- ungültiges Ziel
- API nicht erreichbar

## Erfassung

- gültige Meldung
- fehlender Kommentar, falls optional
- Speicherung
- App-Neustart
- erneutes Laden

## Export

- gültiges GeoJSON
- korrekte Koordinatenreihenfolge
- Properties vorhanden

## Geofence

- außerhalb Schwellenwert
- innerhalb Schwellenwert
- kein wiederholtes Spam-Triggern

---

# 39. Definition of Done für ein Feature

Ein Feature ist erst fertig, wenn:

1. es implementiert ist
2. es kompiliert
3. die App weiterhin startet
4. es manuell getestet wurde
5. Fehlerfälle berücksichtigt sind
6. Code verständlich benannt ist
7. keine Secrets enthalten sind
8. relevante Dokumentation aktualisiert ist

---

# 40. Git-Empfehlung

Projekt von Beginn an mit Git verwalten.

Sinnvolle Commit-Struktur:

```text
feat: add MapLibre map screen
feat: add GPS location service
feat: integrate Open-Meteo
feat: add Overpass POI loading
feat: add bicycle routing
feat: add context scoring
feat: add local report storage
feat: add GeoJSON export
fix: handle denied location permission
docs: update README
```

Keine API-Schlüssel committen.

---

# 41. README-Inhalt für die finale Abgabe

Das finale README sollte mindestens enthalten:

```text
Projektname
Kurzbeschreibung
Studienkontext
Funktionen
Screenshots
Architektur
verwendete Datenquellen
verwendete APIs
Technologiestack
Voraussetzungen
Installation
App starten
APK installieren
Demo-Modus
Build-Anleitung
Datenquellen und Attribution
bekannte Einschränkungen
```

---

# 42. Ausführbarer Code

Ziel:

Android-Release-APK.

Build grundsätzlich über:

```bash
flutter build apk --release
```

Vor Abgabe:

- auf echtem Android-Gerät installieren
- App starten
- Kernworkflow testen
- keine Debug-Abhängigkeit voraussetzen

---

# 43. Projektordner – mögliche finale Struktur

```text
opr_now/
├── android/
├── assets/
│   ├── data/
│   │   ├── test_pois.geojson
│   │   ├── overture_opr.geojson
│   │   └── bathing_sites_opr.geojson
│   └── images/
│
├── lib/
│   ├── app/
│   ├── logic/
│   ├── models/
│   ├── repositories/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   ├── widgets/
│   └── main.dart
│
├── test/
├── tools/
│   └── optional ETL scripts
│
├── .gitignore
├── pubspec.yaml
├── README.md
└── PROJECT_BRAIN.md
```

Optional:

```text
docs/
├── architecture.md
├── data_sources.md
└── project_sketch.pdf
```

---

# 44. ETL-Skripte

Falls Overture oder amtliche Daten vorverarbeitet werden, gehören die Skripte ebenfalls zum Quellcode.

Beispiel:

```text
tools/
├── extract_overture_opr.py
└── prepare_bathing_sites.py
```

Der Prozess muss reproduzierbar dokumentiert werden.

Nicht nur fertige GeoJSON-Dateien abgeben, wenn deren Entstehung Teil des Projekts ist.

---

# 45. Projektskizze – Inhalt für den Einseiter

Die Projektskizze soll später ungefähr folgende Bereiche enthalten:

## Titel

OPR NOW – Kontextsensitiver Geo-Explorer für spontane Ausflüge in Ostprignitz-Ruppin

## Problem

Bestehende touristische Karten zeigen überwiegend statische Informationen. Für spontane Aktivitäten fehlt häufig eine Verbindung zwischen aktuellem Standort, verfügbarer Zeit, Mobilitätsart, Wetter und tatsächlicher Erreichbarkeit.

## Ziel

Entwicklung einer mobilen Location Based App, die unterschiedliche offene und amtliche Geodaten kombiniert und daraus situationsabhängige Freizeitziele sowie passende Routen ableitet.

## Hauptfunktionen

- interaktive Karte
- GPS-Ortung
- POI-Integration
- Wetterintegration
- kontextsensitive Empfehlungen
- Fuß-/Fahrradrouting
- Geofencing
- mobile Geodatenerfassung
- GeoJSON-Export

## Daten

- OpenStreetMap
- Overture Maps
- Open-Meteo
- amtliche Badestellen Brandenburg
- optional VBB

## Technik

- Flutter
- Dart
- MapLibre
- REST APIs
- SQLite
- GeoJSON
- Valhalla

---

# 46. Innovation des Projekts

Die Innovation liegt **nicht** darin, dass Sehenswürdigkeiten auf einer Karte dargestellt werden.

Sie liegt in der Verbindung von:

```text
Ort
+
Zeit
+
Interesse
+
Mobilität
+
Wetter
+
Erreichbarkeit
+
unterschiedlichen Geodaten
```

zu einer räumlich begründeten Entscheidung.

Das Projekt soll daher als **kontextsensitive Location Based App** verstanden und präsentiert werden.

---

# 47. Potenzielle spätere Forschungs-/Entwicklungsfragen

Nicht für den MVP verpflichtend.

Mögliche Vertiefungen:

- Wie können POIs aus mehreren Datenquellen zusammengeführt werden?
- Wie lassen sich Dubletten automatisch erkennen?
- Wie verändert Wetter die Attraktivität unterschiedlicher POI-Typen?
- Wie können mehrere Ziele innerhalb eines Zeitbudgets optimiert werden?
- Wie können Nutzer-Meldungen in Routingentscheidungen einfließen?
- Wie kann Offline-Verfügbarkeit verbessert werden?
- Wie lassen sich Routing und ÖPNV kombinieren?
- Wie können Heading und weitere Smartphone-Sensoren genutzt werden?

---

# 48. Offene Entscheidungen

Diese Punkte sind noch nicht final festgelegt und sollen während der Umsetzung bewusst entschieden werden.

```text
[ ] konkrete MapLibre-Flutter-Bibliothek / Version
[ ] Kartenstil und Tile Provider
[ ] http oder dio
[ ] konkrete Valhalla-Instanz bzw. Hosting des Routingdienstes
[ ] genauer Radius für Overpass-Abfragen
[ ] endgültige POI-Kategorien
[x] Scoring der Context Engine (Phase 7, lib/logic/context_engine.dart): 0,40 Distanz + 0,30 Interesse + 0,20 Wetter + 0,10 weiterer Kontext (POI-Detailtiefe), Ausschluss bei Hin-/Rückreisezeit > Zeitbudget. Gewichtung bleibt ein Entwurfswert und kann bei Bedarf angepasst werden.
[ ] genaue Geofence-Distanz
[ ] genaue SQLite-Struktur
[ ] exakte amtliche Badestellenquelle und Datenformat
[ ] Form der Overture-Extraktion
[ ] Umfang der Offline-Funktion
[ ] Verwendung von Fotos bei Nutzer-Meldungen
[x] genaue UI-Gestaltung (Design-Überarbeitung): Natur/Outdoor-Thema, Waldgrün als Seed-Farbe (`lib/theme/app_theme.dart`), Schriftart Poppins, Light/Dark Mode (folgt Systemeinstellung), eigenes `MapColors`-System für Kartenpunktfarben (getrennt von der UI-Grundfarbe), Kartenkontrollen (Zoom +/-, Legende, selbst gebauter Maßstabsbalken, da `scaleControlEnabled` nur auf Web funktioniert), "Über"-Seite mit Projektbeschreibung, Datenquellen/Attribution und FAQ (`lib/screens/info_screen.dart`).
```

Coding Agents dürfen diese Punkte nicht ohne Begründung als bereits entschieden behandeln.

---

# 49. Technische Entscheidungen vor Implementierung verifizieren

Da Bibliotheken, APIs und Versionen sich ändern können, gilt:

Vor Installation oder Implementierung immer die **aktuelle offizielle Dokumentation** prüfen.

Insbesondere:

- Flutter
- Dart
- MapLibre Flutter
- geolocator
- Overpass API
- Overture Maps
- Open-Meteo
- Valhalla
- sqflite
- Android SDK

Diese Datei definiert die Architektur, aber keine dauerhaft gültigen Versionsnummern.

---

# 50. Prioritäten

Wenn Zeit knapp wird, gilt:

```text
1. stabile App
2. GeoIT-Kernfunktionen
3. nachvollziehbare Datenintegration
4. Routing
5. Context Engine
6. Erfassung + Export
7. Demo-Fähigkeit
8. gute Dokumentation
9. optisches Feintuning
10. optionale Zusatzfeatures
```

Eine kleinere vollständig funktionierende Anwendung ist besser als eine große unfertige Anwendung.

---

# 51. Nicht verhandelbare Projektprinzipien

1. **Mobile First**
2. **GeoIT muss der Kern sein**
3. **mehrere Datenquellen**
4. **Standortbezug**
5. **Routing**
6. **Kontextverarbeitung**
7. **eigene Geodatenerfassung**
8. **reproduzierbarer Quellcode**
9. **ausführbare APK**
10. **kein unnötiges Backend**
11. **MVP vor Zusatzfeatures**
12. **keine erfundenen APIs**
13. **Nutzer muss den Code erklären können**
14. **Demo auch außerhalb von OPR möglich**
15. **offene Geodaten bevorzugen**

---

# 52. Kurzfassung für einen neuen Coding Agent

Wenn nur wenige Sekunden zur Orientierung vorhanden sind:

```text
Projekt:
OPR NOW

Typ:
Flutter-Android-App / Location Based App

Region:
Landkreis Ostprignitz-Ruppin

Ziel:
Aus aktuellem Standort, Zeitbudget, Interessen, Mobilitätsart,
Wetter und POIs geeignete Freizeitziele und Routen ableiten.

Stack:
Flutter + Dart
MapLibre
geolocator
REST APIs
SQLite
GeoJSON
Valhalla

Daten:
OSM / Overpass
Overture Maps
Open-Meteo
amtliche Badestellen Brandenburg
optional VBB

Kern:
Karte
GPS
POIs
Context Engine
Routing
Geofencing
mobile Erfassung
GeoJSON-Export
Demo-Standort

Abgabe:
Quellcode + Android APK

Wichtig:
Kein unnötiges Backend.
Keine Feature-Flut.
MVP zuerst.
Keine erfundenen APIs.
Alle Änderungen nachvollziehbar halten.
```

---

# 53. Arbeitsanweisung an Claude / Antigravity

Bei jeder neuen Entwicklungsaufgabe:

```text
1. PROJECT_BRAIN.md lesen.
2. Relevante bestehende Dateien lesen.
3. Aktuellen Projektstand feststellen.
4. Keine bestehende funktionierende Architektur unnötig ersetzen.
5. Kleine umsetzbare Änderung planen.
6. Änderung implementieren.
7. Kompilierungs- und Analysefehler prüfen.
8. Funktion möglichst testen.
9. Fehlerfälle berücksichtigen.
10. Kurz dokumentieren, was geändert wurde.
11. Falls eine neue dauerhafte Architekturentscheidung getroffen wurde,
    PROJECT_BRAIN.md aktualisieren.
```

Wenn Nutzerwunsch und PROJECT_BRAIN.md widersprechen, gilt der **aktuelle ausdrückliche Nutzerwunsch**.

Wenn etwas technisch unklar ist:

- nicht raten
- aktuelle Dokumentation prüfen
- Unsicherheit benennen
- robuste Lösung wählen

---

# 54. Zielbild

Am Ende soll OPR NOW eine kompakte, demonstrierbare Android-App sein, bei der ein Prüfer unmittelbar erkennen kann:

> Hier werden Geodaten nicht nur angezeigt. Die Anwendung ortet den Nutzer, integriert unterschiedliche räumliche Datenquellen, verarbeitet aktuellen Kontext, führt räumliche Entscheidungen durch, berechnet Routen, reagiert auf räumliche Nähe und ermöglicht selbst die Erfassung und Ausgabe von Geodaten.

Genau dieser GeoIT-Mehrwert hat Vorrang vor einer großen Zahl touristischer Standardfunktionen.
