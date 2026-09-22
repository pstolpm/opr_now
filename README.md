# OPR NOW

Kontextsensitiver Geo-Explorer für spontane Ausflüge im Landkreis Ostprignitz-Ruppin.

Studienprojekt im Master Geoinformation an der Berliner Hochschule für Technik (BHT), Kurs
Geodatenhaltung und -Vernetzung in der GeoIT bei Prof. Dr. Roland Wagner.

Die vollständige fachliche und technische Projektdefinition steht in [`PROJECT_BRAIN.md`](PROJECT_BRAIN.md).

## Projektidee

Die App beantwortet die Frage *„Was kann ich von meinem aktuellen Standort aus jetzt sinnvoll
unternehmen?"*. Dazu verbindet sie GPS-Position, Zeitbudget, Fortbewegungsart, Interessen und Wetter
mit offenen und amtlichen Geodaten, bewertet mögliche Ziele über eine regelbasierte Context Engine
und macht sie per Routing navigierbar. Eigene Beobachtungen können mobil erfasst und als GeoJSON
exportiert werden.

## Funktionsumfang

- Interaktive Karte (MapLibre, Kartenstil OpenFreeMap Liberty) mit Zoom, Legende und Maßstabsbalken
- GPS-Standortbestimmung sowie ein Demo-Standort-Modus für Vorführungen ohne echten Standortzugriff
- POIs aus mehreren Quellen: OpenStreetMap/Overpass und amtliche Badestellen Brandenburg
- aktuelle Wetterdaten von Open-Meteo
- regelbasierte Context Engine, die POIs nach Distanz, Interessen, Wetter und Zeitbudget bewertet
- Fuß- und Fahrradrouting über Valhalla
- Rundtour-Planung: mehrere Stopps werden zu einer Tour mit Rückweg zum Start kombiniert
- Geofence mit automatischer Benachrichtigung bei Ankunft, inklusive Fortschritt durch mehrstufige Rundtouren
- mobile Erfassung eigener Beobachtungen (z. B. Wegsperrungen), lokale Speicherung in SQLite
- Export der eigenen Meldungen als GeoJSON über die Android-Teilen-Funktion
- Info-Seite mit Projektbeschreibung, Quellenangaben und FAQ

## Status

Die geplanten Entwicklungsphasen aus `PROJECT_BRAIN.md` sind umgesetzt, einschließlich der ursprünglich
für später vorgesehenen Rundtour-Funktion, die auf Wunsch vorgezogen wurde. Ein Release-Build wurde
erfolgreich erstellt (siehe unten).

## Technologiestack

- Flutter / Dart
- MapLibre GL Flutter (`maplibre_gl`) für die Kartendarstellung
- `geolocator` für Standortbestimmung
- `dio` für die HTTP-/API-Kommunikation
- `sqflite` für die lokale Speicherung eigener Meldungen
- `share_plus` für den GeoJSON-Export
- Valhalla (FOSSGIS-Instanz) für Routing
- Zielplattform Android (Application-ID `de.pstolpm.oprnow`)

## Voraussetzungen

- Flutter SDK (stable) im PATH
- Android SDK inkl. Platform-Tools und Emulator (z. B. über Android Studio)
- ein Android-Emulator (AVD) oder ein Android-Gerät mit USB-Debugging

Prüfen mit `flutter doctor`.

## App starten

```bash
flutter pub get
flutter emulators --launch <emulator-id>   # oder Gerät anschließen
flutter devices
flutter run -d <device-id>
```

## Demo-Modus

Da die App nicht zwingend vor Ort in Ostprignitz-Ruppin vorgeführt wird, lässt sich in der App
zwischen echtem GPS und mehreren vordefinierten Demo-Standorten im Landkreis wechseln. Der Demo-Modus
ist in der Oberfläche eindeutig als Simulation gekennzeichnet und deckt alle standortbezogenen
Funktionen ab (Empfehlungen, Routing, Rundtour, Geofence).

## Release-APK bauen

```bash
flutter build apk --release
```

Ergebnis: `build/app/outputs/flutter-apk/app-release.apk`

Der Release-Build wird mit dem Debug-Keystore signiert (Standard des Flutter-Templates). Für die
Hochschulabgabe ist das ausreichend; ein Play-Store-Release würde einen eigenen Keystore benötigen.

## Projektstruktur

```text
lib/        Dart-Quellcode der App (app, logic, models, repositories, screens, services, widgets)
android/    Android-Projekt (Gradle)
assets/     lokale Geodaten (Test-POIs, Badestellen) und Bilder
test/       Tests
tools/      Python-Skripte zur Datenaufbereitung (ETL)
```

Die Ordner `ios/`, `web/`, `linux/`, `macos/` und `windows/` stammen aus dem Flutter-Template und
werden in diesem Projekt nicht aktiv genutzt (Zielplattform ist ausschließlich Android).

## Datenquellen und Attribution

**Kartendarstellung**
OpenFreeMap (Stil „Liberty", MIT-Lizenz). Kartendaten: © OpenStreetMap-Mitwirkende, Kartenschema
OpenMapTiles.

**Sehenswürdigkeiten, Natur- und Gastronomieziele**
Overpass API / OpenStreetMap. © OpenStreetMap-Mitwirkende, lizenziert unter der Open Database
License (ODbL).

**Badestellen**
Amtliche Badestellendaten des Landes Brandenburg (badestellen.brandenburg.de). Geodaten:
© Geobasis-DE/LGB. Fachdaten: © Ministerium für Land- und Ernährungswirtschaft, Umwelt und
Verbraucherschutz Brandenburg (MLUK).

**Wetter**
Weather data by [Open-Meteo.com](https://open-meteo.com/), lizenziert unter CC BY 4.0.

**Routing**
Valhalla-Routingserver (openstreetmap.de, betrieben von FOSSGIS e.V.), berechnet auf Basis von
OpenStreetMap-Daten.

**Nutzer-Meldungen**
Von Nutzer:innen selbst erfasste Beobachtungen. Diese Daten verbleiben lokal auf dem Gerät, bis sie
ausdrücklich als GeoJSON exportiert werden.

Dieselben Angaben sind auch in der App selbst unter „Über OPR NOW" einsehbar.

## Bekannte Einschränkungen

- nur für Android gebaut und getestet, kein iOS-/Web-Build
- Kartendarstellung sowie POI-, Wetter- und Routing-Abfragen benötigen eine Internetverbindung;
  offline verfügbar sind nur bereits geladene Daten und eigene, lokal gespeicherte Meldungen
- keine automatische Dublettenprüfung zwischen POI-Quellen (ein Ort kann theoretisch doppelt erscheinen)
- ÖPNV-Anbindung (VBB/GTFS) ist in `PROJECT_BRAIN.md` als mögliche spätere Erweiterung vorgesehen,
  aber nicht umgesetzt
- eine Overture-Maps-Anbindung war geplant; das vorbereitete Asset (`assets/data/overture_opr.geojson`)
  ist aktuell noch leer, da der ETL-Schritt dafür im Projektverlauf nicht mehr benötigt wurde
- der Release-Build war bislang nur im Emulator, nicht auf einem physischen Android-Gerät im Test
