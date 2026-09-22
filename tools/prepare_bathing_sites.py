#!/usr/bin/env python3
"""ETL: laedt die amtlichen Badestellen des Landes Brandenburg und filtert sie
auf den Landkreis Ostprignitz-Ruppin (OPR) - PROJECT_BRAIN Abschnitt 11.4, 44.

Quelle: https://badestellen.brandenburg.de
Attribution laut Portal:
    Geodaten: (c) Geobasis-DE/LGB
    Fachdaten: (c) Ministerium fuer Land- und Ernaehrungswirtschaft,
               Umwelt und Verbraucherschutz Brandenburg

Aufruf:
    python tools/prepare_bathing_sites.py

Ergebnis:
    assets/data/bathing_sites_opr.geojson

Hinweis: Der genaue interne Feldname fuer den Landkreis im KML ist nicht
offiziell dokumentiert. Das Skript sucht deshalb bewusst in allen
ExtendedData-Feldern eines Eintrags nach einem Hinweis auf "OPR" bzw.
"Ostprignitz-Ruppin", statt einen einzelnen Feldnamen fest zu verdrahten.
"""
from __future__ import annotations

import argparse
import json
import re
import ssl
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

# Zertifikatspruefung fuer HTTPS-Anfragen absichern. Manche Netzwerke
# (Schule/Uni, Virenscanner, Firmen-Proxys) klinken sich mit einem eigenen
# Zertifikat in HTTPS-Verbindungen ein; Windows/der Browser kennt und
# vertraut diesem Zertifikat, Pythons eigener Zertifikatsspeicher aber
# nicht - das fuehrt zu 'CERTIFICATE_VERIFY_FAILED'.
#   1. Bevorzugt: truststore, nutzt den Windows-eigenen Zertifikatsspeicher
#      (loest genau dieses Problem).
#   2. Fallback: certifi, ein aktuelles, aber von Windows unabhaengiges
#      Zertifikatsbuendel (hilft, wenn Python-Installationen gar keinen
#      funktionierenden Zertifikatsspeicher mitbringen).
try:
    import truststore

    truststore.inject_into_ssl()
    _SSL_CONTEXT = ssl.create_default_context()
except ImportError:
    try:
        import certifi

        _SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        _SSL_CONTEXT = None

ROOT = Path(__file__).resolve().parent.parent
OUT_PATH = ROOT / "assets" / "data" / "bathing_sites_opr.geojson"

KML_URL = (
    "https://badestellen.brandenburg.de/web/badestellen/badestellen/"
    "-/export/badestellen.kml"
)

# Standard-KML-Namensraum.
NS = {"kml": "http://www.opengis.net/kml/2.2"}

OPR_MARKERS = ("opr", "ostprignitz-ruppin", "ostprignitz ruppin")


def fetch_kml() -> bytes:
    request = urllib.request.Request(
        KML_URL, headers={"User-Agent": "OPR-NOW-Studienprojekt (BHT Berlin)"}
    )
    with urllib.request.urlopen(
        request, timeout=30, context=_SSL_CONTEXT
    ) as response:
        return response.read()


def extended_data(placemark: ET.Element) -> dict[str, str]:
    result: dict[str, str] = {}
    for data in placemark.findall(".//kml:ExtendedData/kml:Data", NS):
        key = data.get("name", "")
        value_el = data.find("kml:value", NS)
        value = value_el.text if value_el is not None else None
        if key:
            result[key] = (value or "").strip()
    return result


def is_opr(fields: dict[str, str]) -> bool:
    return any(
        value and any(marker in value.lower() for marker in OPR_MARKERS)
        for value in fields.values()
    )


# Von badestellen.brandenburg.de uebernommene KML-Feldnamen -> lesbare
# deutsche Bezeichnung. Felder, die hier NICHT aufgefuehrt sind, werden
# verworfen (interne IDs wie Onr/Bnr, redundantes District/Name).
FIELD_LABELS = {
    "Lastmeasurementdate": "Letzte Messung",
    "Temperature": "Wassertemperatur",
    "Visibilitydepth": "Sichttiefe",
    "Smiley": "Wasserqualität",
    "Bacteriology": "Bakteriologische Bewertung",
    "Bodyofwater": "Gewässer",
    "Lavatory": "Toilette",
    "Wastedisposal": "Abfallentsorgung",
    "Gastronomy": "Gastronomie",
    "Lifeguard": "Rettungsschwimmer",
    "Licensee": "Betreiber",
    "Licenseeurl": "Website Betreiber",
    "Parkingarea": "Parkplatz",
    "Sunbathingarea": "Liegewiese",
    "Fishingallowed": "Angeln erlaubt",
    "Campingallowed": "Camping erlaubt",
    "Playground": "Spielplatz",
    "Barbecuearea": "Grillplatz",
    "Aquaticsallowed": "Wassersport erlaubt",
    "Beachcharacter": "Strandbeschaffenheit",
    "Miscellaneous": "Sonstiges",
    "Remarks": "Bemerkungen",
}

# 'Smiley' kodiert die auf dem Portal als Sterne dargestellte
# Badegewaesserqualitaet (evaluation1 = bestes Ergebnis). Werte 3/4 wurden
# in den OPR-Daten nicht beobachtet, aber anhand der Legende auf
# badestellen.brandenburg.de ergaenzt.
QUALITY_LABELS = {
    "evaluation1": "Ausgezeichnet",
    "evaluation2": "Gut",
    "evaluation3": "Ausreichend",
    "evaluation4": "Mangelhaft",
}


def to_feature(placemark: ET.Element, fields: dict[str, str]) -> dict | None:
    name_el = placemark.find("kml:name", NS)
    coords_el = placemark.find(".//kml:Point/kml:coordinates", NS)
    if name_el is None or name_el.text is None or coords_el is None or not coords_el.text:
        return None

    lon_str, lat_str, *_ = coords_el.text.strip().split(",")
    slug = re.sub(r"[^a-z0-9]+", "-", name_el.text.strip().lower()).strip("-")

    # Nur die Felder aus FIELD_LABELS uebernehmen (mit lesbarer deutscher
    # Bezeichnung), alles andere (interne IDs, Redundantes) verwerfen.
    details = {}
    for key, value in fields.items():
        label = FIELD_LABELS.get(key)
        if not label or not value or value == "-":
            continue
        if key == "Smiley":
            value = QUALITY_LABELS.get(value, value)
        details[label] = value

    return {
        "type": "Feature",
        "id": f"brandenburg:{slug}",
        "properties": {
            "name": name_el.text.strip(),
            "category": "badestelle",
            "source": "brandenburg",
            "details": details,
        },
        "geometry": {
            "type": "Point",
            "coordinates": [float(lon_str), float(lat_str)],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=None,
        help=(
            "Optional: Pfad zu einer bereits heruntergeladenen "
            "badestellen.kml (z. B. manuell im Browser gespeichert). Wenn "
            "gesetzt, wird NICHT selbst heruntergeladen - hilfreich, wenn "
            "der direkte Download in diesem Netzwerk/auf diesem Rechner "
            "an einem SSL-/Firewall-Problem scheitert, im Browser aber "
            "funktioniert."
        ),
    )
    args = parser.parse_args()

    if args.input is not None:
        print(f"Lese lokale Datei {args.input} ...")
        raw = args.input.read_bytes()
    else:
        print(f"Lade {KML_URL} ...")
        raw = fetch_kml()

    root = ET.fromstring(raw)

    features = []
    for placemark in root.findall(".//kml:Placemark", NS):
        fields = extended_data(placemark)
        if not is_opr(fields):
            continue
        feature = to_feature(placemark, fields)
        if feature:
            features.append(feature)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(
        json.dumps(
            {"type": "FeatureCollection", "features": features},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"{len(features)} Badestellen im Landkreis OPR geschrieben nach {OUT_PATH}")


if __name__ == "__main__":
    main()
