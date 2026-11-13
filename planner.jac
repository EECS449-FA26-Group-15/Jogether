"""Server endpoints the web page calls: plan three runs, or fetch the example route."""

import json;
import math;
import time;
import traceback;
import urllib.parse;
import urllib.request;
import from geo_data { ELEVATION_M }
import from geo { COORDS, add_place, straight_km_points }
import from landmarks { Landmark, all_landmarks, landmark_named }
import from maps { MapView, route_map }
import from routes {
    RouteResult,
    RunRequest,
    add_runtime_landmark,
    example_route,
    generate_routes,
    known_landmark,
    validate_request
}

glob KM_PER_MILE: float = 1.609344,
     AREA_NAMES: dict[str, str] = {
         "central-campus": "Central Campus",
         "north-campus": "North Campus",
         "downtown": "Downtown"
     },
     USER_AGENT: str = "Jogether-course-project/0.3 (EECS 449, UMich)";

"""One route the page can show: the route, its map picture, and a Google Maps link."""
obj PlannedRoute {
    has route: RouteResult,
        maps_url: str,
        view: MapView;
}

"""What the page shows after the runner taps Generate.

Route distances stay in km; `unit` says which unit the runner picked for display.
`routes` holds up to three routes for the runner to choose from, best fit first.
"""
obj RunPlan {
    has accepted: bool,
        errors: list[str],
        routes: list[PlannedRoute] = [],
        start_note: str = "",
        seconds: float = 0.0,
        is_example: bool = False,
        unit: str = "km";
}

"""How a typed address became a start, or why it could not.

`landmark` is the name the planner starts from: the address itself, registered
as a place of its own. `area` is the area of the nearest curated landmark.
`place` is what the address lookup found; `exact` says whether that was the
house itself rather than just its street.
"""
obj StartMatch {
    has landmark: str = "",
        area: str = "",
        place: str = "",
        exact: bool = False,
        error: str = "";
}

"""What the address lookup gave back.

`reachable` is False when no lookup service could be reached at all, so the
page can say so instead of blaming the address. `exact` is True for a match
with the house number, False for a street-level match.
"""
obj GeoResult {
    has found: bool = False,
        reachable: bool = True,
        exact: bool = False,
        lat: float = 0.0,
        lon: float = 0.0,
        place: str = "";
}

glob Geocoder = Callable[[str], GeoResult],
     TableFetcher = Callable[
         [tuple[float, float], list[tuple[float, float]]],
         list[float] | None
     ],
     ElevationFetcher = Callable[[float, float], float | None];

"""Street words people add after a name, which are dropped one at a time on retry."""
glob STREET_WORDS: list[str] = [
         "dr",
         "drive",
         "st",
         "street",
         "ave",
         "avenue",
         "rd",
         "road",
         "ln",
         "lane",
         "blvd",
         "boulevard",
         "ct",
         "court",
         "pl",
         "place",
         "way",
         "cir",
         "circle",
         "ter",
         "terrace",
         "trl",
         "trail",
         "pkwy",
         "parkway",
         "hwy",
         "highway"
     ],
     MAX_ADDRESS_QUERIES: int = 6,
     NOMINATIM_PAUSE_S: float = 1.0,
     ANN_ARBOR_VIEWBOX: str = "-83.82,42.34,-83.62,42.20",
     ANN_ARBOR_LAT: tuple[float, float] = (42.20, 42.34),
     ANN_ARBOR_LON: tuple[float, float] = (-83.82, -83.62),
     START_SUFFIX: str = " (your start)";

"""Address lookups already done this session, by the text typed."""
glob GEOCODE_CACHE: dict[str, GeoResult] = {};

"""The distance the runner typed, converted to km; NaN if it is not a number."""
def to_km(text: str, unit: str) -> float {
    value = parse_distance(text);
    return value * KM_PER_MILE if unit == "mi" else value;
}

"""A place Google Maps can find: our coordinates when we have them, else the name."""
def map_point(name: str) -> str {
    if name in COORDS {
        (lat, lon) = COORDS[name];
        return f"{lat},{lon}";
    }
    return f"{name}, Ann Arbor, MI";
}

"""Google Maps walking directions for one pass of the route.

A loop goes through every waypoint and back to the start. Out-and-back and
one-way routes are shown from the first stop to the last; the card says how to
get back.
"""
def maps_link(route: RouteResult) -> str {
    stops = [map_point(w.name) for w in route.waypoints];
    if len(stops) < 2 {
        return "";
    }
    closed = route.shape == "loop";
    params: dict[str, str] = {
        "api": "1",
        "origin": stops[0],
        "destination": stops[0] if closed else stops[-1],
        "waypoints": "|".join(stops[1:] if closed else stops[1:-1]),
        "travelmode": "walking"
    };
    if params["waypoints"] == "" {
        del params["waypoints"];
    }
    return "https://www.google.com/maps/dir/?" + urllib.parse.urlencode(params);
}

"""Fetch a URL as JSON with our User-Agent; raises when it cannot be reached."""
def fetch_json(url: str, timeout: int = 10) -> any {
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT});
    with urllib.request.urlopen(req, timeout=timeout) as resp {
        data = json.load(resp);
    }
    return data;
}

"""True inside the box around Ann Arbor that address lookups are limited to."""
def in_ann_arbor(lat: float, lon: float) -> bool {
    return ANN_ARBOR_LAT[0] <= lat <= ANN_ARBOR_LAT[1]
        and ANN_ARBOR_LON[0] <= lon <= ANN_ARBOR_LON[1];
}

"""The queries to try for a typed address, most specific first.

People type extra street words ("Hideaway Ln Dr") or house numbers the map
does not know. Each later query drops one trailing street word, and the second
half of the list drops the house number too, so the street itself can still be
found: "1719 Hideaway Ln Dr" tries "1719 Hideaway Ln", "1719 Hideaway",
"Hideaway Ln Dr", "Hideaway Ln", "Hideaway".
"""
def address_queries(text: str) -> list[str] {
    words = [
        w
        for w in text.replace(",", " ").split()
        if w != ""
    ];
    queries: list[str] = [];
    bases = [words];
    if len(words) > 1 and words[0].isdigit() {
        bases.append(words[1:]);
    }
    for base in bases {
        current = list(base);
        while len(current) > 0 {
            query = " ".join(current);
            if query not in queries {
                queries.append(query);
            }
            if len(current) > 1 and current[-1].lower().rstrip(".") in STREET_WORDS {
                current = current[:-1];
            } else {
                break;
            }
        }
    }
    return queries[:MAX_ADDRESS_QUERIES];
}

"""The house itself from the US Census geocoder, which interpolates house
numbers along US streets; not found when it has no match inside Ann Arbor.
Raises when the service cannot be reached.
"""
def census_search(address: str) -> GeoResult {
    text = address if "ann arbor" in address.lower() else f"{address}, Ann Arbor, MI";
    url = "https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?"
        + urllib.parse.urlencode(
            {"address": text, "benchmark": "Public_AR_Current", "format": "json"}
        );
    data = fetch_json(url, 12);
    for hit in data.get("result", {}).get("addressMatches", []) {
        lat = float(hit["coordinates"]["y"]);
        lon = float(hit["coordinates"]["x"]);
        if not in_ann_arbor(lat, lon) {
            continue;
        }
        place = str(hit.get("matchedAddress", address)).split(",")[0].strip().title();
        return GeoResult(
            found=True, exact=True, lat=lat, lon=lon, place=place or address
        );
    }
    return GeoResult(found=False);
}

"""One Nominatim search limited to the Ann Arbor area; raises when unreachable."""
def nominatim_search(query: str) -> list[dict[str, any]] {
    text = query if "ann arbor" in query.lower() else f"{query}, Ann Arbor, Michigan";
    url = "https://nominatim.openstreetmap.org/search?"
        + urllib.parse.urlencode(
            {
                "q": text,
                "format": "json",
                "limit": 1,
                "countrycodes": "us",
                "viewbox": ANN_ARBOR_VIEWBOX,
                "bounded": 1
            }
        );
    return fetch_json(url, 10);
}

"""A Nominatim hit as a result: a house when the name starts with its number."""
def nominatim_result(hit: dict[str, any], query: str) -> GeoResult {
    parts = [p.strip() for p in str(hit.get("display_name", query)).split(",")];
    exact = len(parts) > 1 and parts[0].isdigit();
    place = f"{parts[0]} {parts[1]}" if exact else (parts[0] if parts else query);
    return GeoResult(
        found=True,
        exact=exact,
        lat=float(hit["lat"]),
        lon=float(hit["lon"]),
        place=place or query
    );
}

"""Where a typed address is.

The US Census geocoder is asked first, because it knows house numbers. Then
OpenStreetMap Nominatim is tried with the address as typed and shorter forms
of it (see `address_queries`), pausing between calls as its usage policy asks,
which finds at least the street. Needs the network; results are cached.
"""
def geocode(address: str) -> GeoResult {
    text = address.strip()[:200];
    if text == "" {
        return GeoResult();
    }
    if text in GEOCODE_CACHE {
        return GEOCODE_CACHE[text];
    }
    reachable = False;
    census: GeoResult | None = None;
    try {
        census = census_search(text);
    } except Exception {
        census = None;
    }
    if census is not None {
        reachable = True;
        if census.found {
            GEOCODE_CACHE[text] = census;
            return census;
        }
    }
    for (i, query) in enumerate(address_queries(text)) {
        if i > 0 {
            time.sleep(NOMINATIM_PAUSE_S);
        }
        try {
            hits = nominatim_search(query);
        } except Exception {
            continue;
        }
        reachable = True;
        if len(hits) == 0 {
            continue;
        }
        result = nominatim_result(hits[0], query);
        GEOCODE_CACHE[text] = result;
        return result;
    }
    return GeoResult(found=False, reachable=reachable);
}

"""Name of the curated landmark closest to a coordinate, or "" when none is within 2 km."""
def nearest_landmark(lat: float, lon: float) -> str {
    best = "";
    best_km = 2.0;
    for lm in all_landmarks() {
        if lm.name not in COORDS {
            continue;
        }
        (plat, plon) = COORDS[lm.name];
        d = straight_km_points(lat, lon, plat, plon);
        if d < best_km {
            best = lm.name;
            best_km = d;
        }
    }
    return best;
}

"""Walking distances in km from one point to many, from the OSRM foot router's
table service in a single call; None when it cannot be reached or answers oddly.
"""
def osrm_table_km(
    origin: tuple[float, float], targets: list[tuple[float, float]]
) -> list[float] | None {
    if len(targets) == 0 {
        return [];
    }
    coords = ";".join(
        [f"{origin[1]},{origin[0]}"] + [f"{t[1]},{t[0]}" for t in targets]
    );
    url = (
        "https://routing.openstreetmap.de/routed-foot/table/v1/foot/"
        + coords
        + "?sources=0&annotations=distance"
    );
    data = fetch_json(url, 10);
    row = data["distances"][0][1:];
    if len(row) != len(targets) {
        return None;
    }
    return [float(m) / 1000.0 if m is not None else float("nan") for m in row];
}

"""Height above sea level from Open-Meteo, or None when it cannot be reached."""
def open_meteo_elevation(lat: float, lon: float) -> float | None {
    url = "https://api.open-meteo.com/v1/elevation?"
        + urllib.parse.urlencode({"latitude": lat, "longitude": lon});
    data = fetch_json(url, 8);
    values = data.get("elevation", []);
    return float(values[0]) if len(values) > 0 else None;
}

"""Make a found address a place routes can start from, and name it.

The place gets its coordinates, its elevation (Open-Meteo, else the nearest
landmark's) and walking distances to every curated landmark (one OSRM table
call; pairs it misses fall back to straight-line estimates). It must lie
within 2 km of a curated landmark, whose area becomes the request's area.
"""
def register_start(
    found: GeoResult,
    table: TableFetcher = osrm_table_km,
    elevation: ElevationFetcher = open_meteo_elevation
) -> StartMatch {
    nearest = nearest_landmark(found.lat, found.lon);
    if nearest == "" {
        return StartMatch(
            error=f'"{found.place}" is more than 2 km from every place we know. Try an address closer to campus or downtown, or leave the start blank.'
        );
    }
    near = landmark_named(nearest);
    area = near.area if near is not None else "";
    name = found.place + START_SUFFIX;
    if known_landmark(name) is None {
        targets = [
            lm
            for lm in all_landmarks()
            if lm.name in COORDS
        ];
        kms: list[float] = [];
        try {
            got = table((found.lat, found.lon), [COORDS[lm.name] for lm in targets]);
            kms = got if got is not None else [];
        } except Exception {
            kms = [];
        }
        walk: dict[str, float] = {};
        if len(kms) == len(targets) {
            for (i, lm) in enumerate(targets) {
                if math.isfinite(kms[i]) and kms[i] > 0 {
                    walk[lm.name] = round(kms[i], 3);
                }
            }
        }
        height: float | None = None;
        try {
            height = elevation(found.lat, found.lon);
        } except Exception {
            height = None;
        }
        if height is None {
            height = ELEVATION_M.get(nearest, 0.0);
        }
        add_place(name, found.lat, found.lon, height, walk);
        add_runtime_landmark(
            Landmark(
                name=name,
                area=area,
                description="Your start address",
                lighting="unknown",
                surface="pavement",
                good_times=["morning", "afternoon", "evening"],
                tags=[]
            )
        );
    }
    return StartMatch(landmark=name, area=area, place=found.place, exact=found.exact);
}

"""The start for a typed address: the address itself as a place to run from.

An empty address means no fixed start. An address that cannot be found, or is
far from every landmark, gives an error message for the runner instead.
"""
def start_for_address(
    address: str,
    geocoder: Geocoder = geocode,
    table: TableFetcher = osrm_table_km,
    elevation: ElevationFetcher = open_meteo_elevation
) -> StartMatch {
    text = address.strip()[:200];
    if text == "" {
        return StartMatch();
    }
    found = geocoder(text);
    if not found.reachable {
        return StartMatch(
            error="We could not reach the address lookup services. Check your connection, or leave the start blank."
        );
    }
    if not found.found {
        return StartMatch(
            error=f'We could not find "{text}" in Ann Arbor. Try the street name with its number, like "500 S State St", or leave the start blank.'
        );
    }
    return register_start(found, table, elevation);
}

"""Turn the distance text from the form into a number; NaN fails validation."""
def parse_distance(text: str) -> float {
    try {
        return float(text);
    } except ValueError {
        return float("nan");
    }
}

"""Validation messages use field names; show the labels the runner sees instead.

For a runner who picked miles, the distance range is given in miles.
"""
def friendly(error: str, unit: str = "km") -> str {
    if unit == "mi" and error.startswith("distance_km") {
        low = 0.5 / KM_PER_MILE;
        high = 10.0 / KM_PER_MILE;
        return f"Distance must be a number between {low:.1f} and {high:.1f} miles";
    }
    labels: dict[str, str] = {
        "distance_km": "Distance",
        "time_of_day": "Time of day",
        "level": "Level",
        "area": "Area"
    };
    for (field, label) in labels.items() {
        if error.startswith(field) {
            return label + error[len(field):];
        }
    }
    return error;
}

"""A route with its map and Google Maps link, ready for the page."""
def planned(route: RouteResult) -> PlannedRoute {
    return PlannedRoute(route=route, maps_url=maps_link(route), view=route_map(route));
}

"""The sentence above the route cards that says where the routes start."""
def start_sentence(matched: StartMatch, area_before: str) -> str {
    where = (
        f"Routes start at {matched.place}, your address."
            if matched.exact
            else f"We could not place the house number, so routes start at {matched.place}, the closest match to your address."
    );
    if matched.area != "" and matched.area != area_before {
        where += f" That is in {AREA_NAMES.get(
            matched.area, matched.area
        )}, so the area was switched.";
    }
    return where;
}

"""Validate the answers, make the address the start, then plan three routes."""
def:pub plan_run(
    level: str,
    distance: str,
    unit: str,
    area: str,
    time_of_day: str,
    notes: str,
    address: str = "",
    shape: str = "any"
) -> RunPlan {
    unit = "mi" if unit == "mi" else "km";
    start = "";
    start_note = "";
    if address.strip() != "" {
        matched = start_for_address(address);
        if matched.error != "" {
            return RunPlan(accepted=False, errors=[matched.error], unit=unit);
        }
        start = matched.landmark;
        start_note = start_sentence(matched, area);
        if matched.area != "" {
            area = matched.area;
        }
    }
    request = RunRequest(
        level=level,
        distance_km=to_km(distance, unit),
        area=area,
        time_of_day=time_of_day,
        notes=notes.strip()[:300],
        start=start,
        shape=shape.strip() or "any"
    );
    checked = validate_request(request);
    if not checked.accepted {
        return RunPlan(
            accepted=False,
            errors=[friendly(e, unit) for e in checked.errors],
            unit=unit
        );
    }
    started = time.time();
    routes: list[RouteResult] = [];
    try {
        routes = generate_routes(request);
    } except Exception as err {
        traceback.print_exc();
        kind = type(err).__name__;
        return RunPlan(
            accepted=True,
            errors=[
                f"The route planner is not available right now ({kind}). Is Ollama running?"
            ],
            seconds=round(time.time() - started, 1),
            unit=unit
        );
    }
    seconds = round(time.time() - started, 1);
    if len(routes) == 0 {
        return RunPlan(
            accepted=True,
            errors=[
                "The AI could not produce a route that passed our check. Try again or change your answers."
            ],
            seconds=seconds,
            unit=unit
        );
    }
    return RunPlan(
        accepted=True,
        errors=[],
        routes=[planned(r) for r in routes],
        start_note=start_note,
        seconds=seconds,
        unit=unit
    );
}

"""The hand-written example route, clearly marked as not AI-generated."""
def:pub sample_run(unit: str) -> RunPlan {
    return RunPlan(
        accepted=True,
        errors=[],
        routes=[planned(example_route())],
        is_example=True,
        unit="mi" if unit == "mi" else "km"
    );
}
