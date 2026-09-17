# OPR NOW

**Kontextsensitiver Geo-Explorer für spontane Ausflüge im Landkreis Ostprignitz-Ruppin**

Hochschulprojekt im Masterstudiengang Geoinformation (Geodatenhaltung und -Vernetzung in der GeoIT).
Mobile Location Based App für Android, entwickelt mit Flutter und Dart.

Die verbindliche fachliche und technische Projektdefinition steht in [`PROJECT_BRAIN.md`](PROJECT_BRAIN.md).

## Projektidee

Die App beantwortet die Frage *„Was kann ich von meinem aktuellen Standort aus jetzt sinnvoll unternehmen?“*.
Dazu verbindet sie GPS-Position, Zeitbudget, Fortbewegungsart, Interessen und Wetter mit offenen und
amtlichen Geodaten (OpenStreetMap, Overture Maps, Open-Meteo, Badestellen Brandenburg), bewertet
Ziele über eine regelbasierte Context Engine und macht sie per Routing navigierbar. Eigene Geoobjekte
können mobil erfasst und als GeoJSON exportiert werden.

## Status

Phase 1 abgeschlossen: Flutter-Projekt erzeugt, Android-Toolchain eingerichtet, App startet im Emulator.
Die fachliche Implementierung beginnt mit Phase 2 (Karte). Siehe Entwicklungsphasen in `PROJECT_BRAIN.md`.

## Technologiestack

- Flutter 3.47 / Dart 3.13
- Zielplattform Android (Application-ID `de.pstolpm.oprnow`)
- geplant: MapLibre (Karte), geolocator (Standort), SQLite (lokale Speicherung), Valhalla (Routing)

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

## Release-APK bauen

```bash
flutter build apk --release
```

Ergebnis: `build/app/outputs/flutter-apk/app-release.apk`

Hinweis: Der Release-Build wird derzeit mit dem Debug-Keystore signiert (Standard des Flutter-Templates).
Für die Hochschulabgabe ist das ausreichend; ein Play-Store-Release würde einen eigenen Keystore benötigen.

## Projektstruktur

```text
lib/        Dart-Quellcode der App
android/    Android-Projekt (Gradle)
test/       Tests
docs/       Projektdokumentation
```

Die Ordner `ios/`, `web/`, `linux/`, `macos/` und `windows/` stammen aus dem Flutter-Template und werden
in diesem Projekt nicht aktiv genutzt.

## Datenquellen und Attribution

Wird ergänzt, sobald die jeweiligen Quellen eingebunden sind (OpenStreetMap-Mitwirkende, Overture Maps,
Open-Meteo, Land Brandenburg, verwendeter Kartenstil / Tile-Provider, Routingdienst).

## Bekannte Einschränkungen

Wird im Projektverlauf gepflegt.
