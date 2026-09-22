#!/usr/bin/env python3
"""ETL: laedt Overture-Maps-"Places" fuer den Landkreis Ostprignitz-Ruppin
(OPR) und wandelt sie in unser App-POI-Schema um - PROJECT_BRAIN Abschnitt
11.2, 44.

Voraussetzung (einmalig):
    pip install overturemaps

Aufruf:
    python tools/extract_overture_opr.py

Ergebnis:
    assets/data/overture_opr.geojson

Hinweis zum Schema: Overture hat im Dezember-2025-Release von
`categories.primary` auf `taxonomy.primary` / `basic_category`
umgestellt (`categories.primary` wird laut Overture-Doku im
September-2026-Release entfernt). Das Skript prueft deshalb mehrere
moegliche Feldnamen, statt sich auf einen einzelnen zu verlassen.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW_PATH = ROOT / "tools" / "_overture_places_raw.geojson"
OUT_PATH = ROOT / "assets" / "data" / "overture_opr.geojson"

# xmin,ymin,xmax,ymax - identisch zu MapConstants.oprBounds in
# lib/utils/constants.dart.
BBOX = "12.20,52.68,13.15,53.30"

# Overture-Kategoriewerte -> unsere vier App-Kategorien. Bewusst auf die
# Kategorien begrenzt, die wir auch auswerten/einfaerben (siehe
# map_screen.dart) - andere Overture-Places-Kategorien werden übersprungen.
CATEGORY_MAP = {
    "museum": "sehenswuerdigkeit",
    "art_museum": "sehenswuerdigkeit",
    "historical_landmark": "sehenswuerdigkeit",
    "monument": "sehenswuerdigkeit",
    "castle": "sehenswuerdigkeit",
    "viewpoint": "natur",
    "nature_reserve": "natur",
    "beach": "badestelle",
    "restaurant": "gastronomie",
    "cafe": "gastronomie",
    "casual_eatery": "gastronomie",
    "fast_food_restaurant": "gastronomie",
    "bar": "gastronomie",
}


def download_raw() -> None:
    print(f"Lade Overture Places (Theme 'place') fuer Bounding Box {BBOX} ...")
    subprocess.run(
        [
            "overturemaps", "download",
            "--bbox", BBOX,
            "-f", "geojson",
            "-t", "place",
            "-o", str(RAW_PATH),
        ],
        check=True,
    )


def category_for(properties: dict) -> str | None:
    candidates = [
        properties.get("basic_category"),
        (properties.get("taxonomy") or {}).get("primary"),
        (properties.get("categories") or {}).get("primary"),  # aeltere Releases
    ]
    for value in candidates:
        if value and value in CATEGORY_MAP:
            return CATEGORY_MAP[value]
    return None


def transform() -> None:
    raw = json.loads(RAW_PATH.read_text(encoding="utf-8"))
    features = []
    for feature in raw.get("features", []):
        props = feature.get("properties") or {}
        name = (props.get("names") or {}).get("primary")
        if not name:
            continue
        category = category_for(props)
        if category is None:
            continue
        features.append({
            "type": "Feature",
            "id": f"overture:{feature.get('id')}",
            "properties": {
                "name": name,
                "category": category,
                "source": "overture",
            },
            "geometry": feature.get("geometry"),
        })

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(
        json.dumps(
            {"type": "FeatureCollection", "features": features},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"{len(features)} Overture-POIs geschrieben nach {OUT_PATH}")


def main() -> None:
    download_raw()
    transform()
    RAW_PATH.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
