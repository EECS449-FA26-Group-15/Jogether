"""Server endpoints the web page calls: plan three runs, or fetch the example route."""

import json;
import time;
import traceback;
import urllib.parse;
import urllib.request;
import from geo { COORDS, straight_km_points }
import from landmarks { all_landmarks, landmark_named }
import from maps { MapView, route_map }
import from routes {
    RouteResult,
    RunRequest,
    example_route,
    generate_routes,
    validate_request
}

glob KM_PER_MILE: float = 1.609344,
     AREA_NAMES: dict[str, str] = {
         "central-campus": "Central Campus",
         "north-campus": "North Campus",
         "downtown": "Downtown"
     };

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

"""How a typed address became a start: the landmark and its area, or why not.

`place` is the name of what the address lookup found, for the note on the page.
"""
obj StartMatch {
    has landmark: str = "",
        area: str = "",
        place: str = "",
        error: str = "";
}

"""What the address lookup gave back.

`reachable` is False when the lookup service could not be reached at all, so
the page can say so instead of blaming the address.
"""
obj GeoResult {
    has found: bool = False,
        reachable: bool = True,
        lat: float = 0.0,
        lon: float = 0.0,
        place: str = "";
}

glob Geocoder = Callable[[str], GeoResult];

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
     ANN_ARBOR_VIEWBOX: str = "-83.82,42.34,-83.62,42.20";

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
    req = urllib.request.Request(
        url, headers={"User-Agent": "Jogether-course-project/0.3 (EECS 449, UMich)"}
    );
    with urllib.request.urlopen(req, timeout=10) as resp {
        hits = json.load(resp);
    }
    return hits;
}

"""Where a typed address is, from OpenStreetMap Nominatim.

Tries the address as typed, then shorter forms of it (see `address_queries`),
pausing between calls as Nominatim's usage policy asks. Needs the network.
"""
def geocode(address: str) -> GeoResult {
    text = address.strip()[:200];
    if text == "" {
        return GeoResult();
    }
    reachable = False;
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
        place = str(hits[0].get("display_name", query)).split(",")[0].strip() or query;
        return GeoResult(
            found=True,
            reachable=True,
            lat=float(hits[0]["lat"]),
            lon=float(hits[0]["lon"]),
            place=place
        );
    }
    return GeoResult(found=False, reachable=reachable);
}

"""Name of the landmark closest to a coordinate, or "" when none is within 2 km."""
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

"""The start for a typed address: the nearest landmark within 2 km and its area.

An empty address means no fixed start. An address that cannot be found, or has
no landmark near it, gives an error message for the runner instead.
"""
def start_for_address(address: str, geocoder: Geocoder = geocode) -> StartMatch {
    text = address.strip()[:200];
    if text == "" {
        return StartMatch();
    }
    found = geocoder(text);
    if not found.reachable {
        return StartMatch(
            error="We could not reach the address lookup service (OpenStreetMap Nominatim). Check your connection, or leave the start blank."
        );
    }
    if not found.found {
        return StartMatch(
            error=f'We could not find "{text}" in Ann Arbor. Try the street name with its number, like "500 S State St", or leave the start blank.'
        );
    }
    name = nearest_landmark(found.lat, found.lon);
    if name == "" {
        return StartMatch(
            error=f'No landmark within 2 km of "{found.place}". Try an address closer to campus or downtown, or leave the start blank.'
        );
    }
    landmark = landmark_named(name);
    return StartMatch(
        landmark=name,
        area=landmark.area if landmark is not None else "",
        place=found.place
    );
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

"""Validate the answers, match the address to a start, then plan three routes."""
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
        place = matched.place if matched.place != "" else "your address";
        if matched.area != "" and matched.area != area {
            area = matched.area;
            start_note = f"{place} is nearest to {start} ({AREA_NAMES.get(
                area, area
            )}), so the routes start there.";
        } else {
            start_note = f"Routes start at {start}, the landmark nearest to {place}.";
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
