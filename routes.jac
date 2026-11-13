"""Validate a run request and plan a route from known landmarks.

Division of labour:
- code picks the landmark pool, measures candidate routes (geo.jac) and checks
  the result;
- the LLM turns the runner's free-text notes into structured preferences, then
  writes the words on the route cards: one card per measured option on the web
  page (`generate_routes`), or one chosen option for the CLI (`generate_route`).
"""

import math;
import from landmarks {
    AREAS,
    Landmark,
    TAGS,
    all_landmarks,
    landmark_named,
    landmarks_for
}
import from geo {
    COORDS,
    RouteOption,
    SHAPES,
    loop_km,
    route_options,
    straight_km_points
}

obj RunRequest {
    has level: str,
        distance_km: float,
        area: str,
        time_of_day: str,
        notes: str = "",
        start: str = "",
        shape: str = "any";
}

obj ValidationResult {
    has accepted: bool,
        errors: list[str],
        request: RunRequest;
}

glob LEVELS: list[str] = ["beginner", "intermediate", "experienced"],
     TIMES: list[str] = ["morning", "afternoon", "evening"],
     SHAPE_CHOICES: list[str] = ["any"] + SHAPES;

def validate_request(request: RunRequest) -> ValidationResult {
    errors: list[str] = [];
    if request.level not in LEVELS {
        errors.append("level must be beginner, intermediate, or experienced");
    }
    if not math.isfinite(request.distance_km)
        or not (0.5 <= request.distance_km <= 10.0) {
        errors.append("distance_km must be finite and between 0.5 and 10 km");
    }
    if request.area not in AREAS {
        errors.append("area must be central-campus, north-campus, or downtown");
    }
    if request.time_of_day not in TIMES {
        errors.append("time_of_day must be morning, afternoon, or evening");
    }
    if request.start != "" and landmark_named(request.start) is None {
        errors.append("start must be a known landmark or empty");
    }
    if request.shape not in SHAPE_CHOICES {
        errors.append("shape must be any, loop, out-and-back, or one-way");
    }
    return ValidationResult(accepted=len(errors) == 0, errors=errors, request=request);
}

"""What the runner asked for in their own words, as structured fields."""
obj Preferences {
    has wants: list[str] = [],
        avoids: list[str] = [],
        avoid_hills: bool = False,
        shape: str = "any";
}

sem Preferences.wants = "Landmark tags the runner would like on the route, only from: river, park, nature, trail, campus, shops, historic, quiet, busy, stadium, track, hill, flat";
sem Preferences.avoids = "Landmark tags the runner wants to avoid, from the same list";
sem Preferences.avoid_hills = "True if the runner asks for a flat run or says no hills";
sem Preferences.shape = "loop (end where you start), out-and-back (same way back), one-way (end elsewhere), or any if not stated";

"""Read the runner's notes and return only what they actually ask for.

Leave fields empty when the notes do not mention them. Use only the listed tags.
"""
def parse_notes(notes: str) -> Preferences by llm();

glob PrefParser = Callable[[str], Preferences];

"""Preferences for a request: parsed from the notes when there are any."""
def preferences_for(
    request: RunRequest, parser: PrefParser = parse_notes
) -> Preferences {
    text = request.notes.strip();
    if text == "" {
        return Preferences();
    }
    try {
        prefs = parser(text);
    } except Exception {
        return Preferences();
    }
    prefs.wants = [
        t
        for t in prefs.wants
        if t in TAGS
    ];
    prefs.avoids = [
        t
        for t in prefs.avoids
        if t in TAGS and t not in prefs.wants
    ];
    if prefs.shape not in SHAPE_CHOICES {
        prefs.shape = "any";
    }
    return prefs;
}

"""Per-landmark preference score: +1 per wanted tag, -1 per avoided tag."""
def preference_bonus(
    landmarks: list[Landmark], prefs: Preferences
) -> dict[str, float] {
    bonus: dict[str, float] = {};
    for lm in landmarks {
        score = 0.0;
        for tag in lm.tags {
            if tag in prefs.wants {
                score += 1.0;
            }
            if tag in prefs.avoids {
                score -= 1.0;
            }
        }
        bonus[lm.name] = score;
    }
    return bonus;
}

"""One stop on a route, named after a landmark from landmarks.jac."""
obj Waypoint {
    has name: str,
        note: str;
}

"""The route shape shared by the route agent and the result page.

`distance_km` and `climb_m` are measured by code from landmark coordinates (see
geo.jac): one pass of the route in its `shape`, times `laps`.
"""
obj RouteResult {
    has title: str,
        waypoints: list[Waypoint],
        distance_km: float,
        difficulty: int,
        difficulty_reason: str,
        safety_notes: list[str],
        laps: int = 1,
        shape: str = "loop",
        climb_m: float = 0.0;
}

"""What the LLM decides: which measured option to run, and how to describe it."""
obj RoutePick {
    has option: int,
        title: str,
        stops: list[Waypoint],
        difficulty: int,
        difficulty_reason: str,
        safety_notes: list[str];
}

sem RunRequest.notes = "Optional extra wishes from the runner in their own words; follow them when the options allow";
sem RunRequest.start = "Landmark the route must start at, or empty for anywhere in the area";
sem RunRequest.shape = "Wanted route shape: loop, out-and-back, one-way, or any";
sem Waypoint.name = "Exact name of a landmark from the given list";
sem Waypoint.note = "One line on what the runner sees or does here";
sem RoutePick.option = "0-based index of the chosen option in the options list";
sem RoutePick.title = "Short route name that matches the chosen stops and shape (say loop only for a loop); do not mention places that are not on the route";
sem RoutePick.stops = "Each stop of the chosen option with a short note about that stop";
sem RoutePick.difficulty = "1 (easiest) to 5 (hardest)";
sem RoutePick.safety_notes = "At most 3 notes for the chosen time of day";

"""Hand-written sample route for building the result page without an LLM."""
def example_route -> RouteResult {
    stops = ["Michigan Union", "The Diag", "Ingalls Mall", "Burton Memorial Tower"];
    return RouteResult(
        title="Central campus starter loop",
        waypoints=[
            Waypoint(name=stops[0], note="Start on the State Street steps"),
            Waypoint(name=stops[1], note="Cut across the paved paths"),
            Waypoint(name=stops[2], note="Easy stretch along the lawn"),
            Waypoint(name=stops[3], note="Turn back toward State Street")
        ],
        distance_km=round(loop_km(stops), 1),
        difficulty=1,
        difficulty_reason="Short, flat and paved, with plenty of places to stop",
        safety_notes=[
            "Watch for bikes and scooters crossing the Diag",
            "Cross State Street at the signals"
        ]
    );
}

"""Choose the running route that best fits this runner, then describe it.

Each option is already measured: run its stops in order in its shape (loop:
back to the first stop; out-and-back: turn around at the last stop; one-way:
finish at the last stop) and repeat for its laps. Pick the option whose stops
best match the runner's level, time of day and own words (notes), using the
landmark descriptions, tags, lighting and surfaces. Do not change, add or
reorder stops. Rate difficulty from the option's distance, climb, laps, the
runner's level and the surfaces. Base safety notes on the chosen stops'
lighting and the time of day.
"""
def plan_route(
    request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
) -> RoutePick by llm();

"""Every measured option described for this runner, best fit first."""
obj RouteChoices {
    has picks: list[RoutePick];
}

sem RouteChoices.picks = "One pick per option in the options list, each with its own 0-based option index, ordered from the best fit for this runner to the least";

"""Describe every running route option for this runner, best fit first.

Each option is already measured: run its stops in order in its shape (loop:
back to the first stop; out-and-back: turn around at the last stop; one-way:
finish at the last stop) and repeat for its laps. Return one pick for every
option, each with that option's 0-based index, ordered from the option whose
stops best match the runner's level, time of day and own words (notes) to the
least fitting, using the landmark descriptions, tags, lighting and surfaces.
Do not change, add or reorder stops. Give each pick its own title. Rate each
difficulty from that option's distance, climb, laps, the runner's level and
the surfaces. Base each pick's safety notes on its own stops' lighting and the
time of day.
"""
def plan_routes(
    request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
) -> RouteChoices by llm();

"""Turn the LLM's pick into a route; None if it names an option that does not exist.

Notes are matched to stops by name, so a note can never land on the wrong stop.
A stop the LLM did not describe gets its landmark description instead.
"""
def build_route(
    pick: RoutePick, options: list[RouteOption], landmarks: list[Landmark]
) -> RouteResult | None {
    if not (0 <= pick.option < len(options)) {
        return None;
    }
    chosen = options[pick.option];
    written = {
        w.name: w.note
        for w in pick.stops
        if w.note.strip()
    };
    described = {lm.name: lm.description for lm in landmarks};
    waypoints = [
        Waypoint(name=stop, note=written.get(stop, described.get(stop, "")))
        for stop in chosen.stops
    ];
    return RouteResult(
        title=pick.title,
        waypoints=waypoints,
        distance_km=chosen.distance_km,
        difficulty=pick.difficulty,
        difficulty_reason=pick.difficulty_reason,
        safety_notes=pick.safety_notes,
        laps=chosen.laps,
        shape=chosen.shape,
        climb_m=chosen.climb_m
    );
}

"""Return problems with a generated route; an empty list means it passes."""
def check_route(route: RouteResult, landmarks: list[Landmark]) -> list[str] {
    errors: list[str] = [];
    names = [landmark.name for landmark in landmarks];
    if len(route.waypoints) == 0 {
        errors.append("route has no waypoints");
    } elif len(route.waypoints) > MAX_WAYPOINTS {
        errors.append(f"at most {MAX_WAYPOINTS} waypoints");
    }
    on_route = [w.name for w in route.waypoints];
    for waypoint in route.waypoints {
        if waypoint.name not in names {
            errors.append(f"unknown landmark: {waypoint.name}");
        }
    }
    for name in names {
        if name not in on_route and name.lower() in route.title.lower() {
            errors.append(f"title mentions a place not on the route: {name}");
        }
    }
    if not (math.isfinite(route.distance_km) and route.distance_km > 0) {
        errors.append("distance_km must be a positive number");
    }
    if not (1 <= route.difficulty <= 5) {
        errors.append("difficulty must be 1 to 5");
    }
    if len(route.safety_notes) > 3 {
        errors.append("at most 3 safety notes");
    }
    return errors;
}

glob Planner = Callable[
         [RunRequest, list[Landmark], list[RouteOption]],
         RoutePick
     ],
     ChoicePlanner = Callable[
         [RunRequest, list[Landmark], list[RouteOption]],
         RouteChoices
     ],
     MAX_WAYPOINTS: int = 6,
     MIN_REACH_KM: float = 1.2,
     REACH_FACTOR: float = 0.6;

"""Landmarks in an area that suit the time of day, or all of them if fewer than 3 do."""
def landmarks_for_time(area: str, time_of_day: str) -> list[Landmark] {
    return fit_for_time(landmarks_for(area), time_of_day);
}

"""Keep the landmarks that suit the time of day, or all of them if fewer than 3 do."""
def fit_for_time(landmarks: list[Landmark], time_of_day: str) -> list[Landmark] {
    suitable = [
        lm
        for lm in landmarks
        if time_of_day in lm.good_times
    ];
    return suitable if len(suitable) >= 3 else landmarks;
}

"""Where the route is anchored: the start landmark, else the middle of the area."""
def anchor_for(request: RunRequest) -> tuple[float, float] {
    if request.start != "" and request.start in COORDS {
        return COORDS[request.start];
    }
    home = [
        lm.name
        for lm in landmarks_for(request.area)
        if lm.name in COORDS
    ];
    lat = sum([COORDS[n][0] for n in home]) / len(home);
    lon = sum([COORDS[n][1] for n in home]) / len(home);
    return (lat, lon);
}

"""Landmarks for this request: the area's own, plus any landmark from a
neighbouring area close enough for the requested distance; right for the time
of day; no dirt trails for beginners; always including the chosen start."""
def landmarks_for_request(request: RunRequest) -> list[Landmark] {
    (lat, lon) = anchor_for(request);
    reach = max(MIN_REACH_KM, REACH_FACTOR * request.distance_km);
    pool = [
        lm
        for lm in all_landmarks()
        if lm.area == request.area
            or (
                lm.name in COORDS
                and straight_km_points(lat, lon, COORDS[lm.name][0], COORDS[lm.name][1])
                    <= reach
            )
    ];
    landmarks = fit_for_time(pool, request.time_of_day);
    if request.level == "beginner" {
        easier = [
            lm
            for lm in landmarks
            if lm.surface != "dirt trail"
        ];
        if len(easier) >= 3 {
            landmarks = easier;
        }
    }
    if request.start != "" and all([lm.name != request.start for lm in landmarks]) {
        chosen = landmark_named(request.start);
        if chosen is not None {
            landmarks = [chosen] + landmarks;
        }
    }
    return landmarks;
}

"""Measured candidate routes for a request, shaped by the runner's preferences."""
def options_for(
    request: RunRequest,
    landmarks: list[Landmark],
    prefs: Preferences,
    seed: int | None = None
) -> list[RouteOption] {
    shape = request.shape if request.shape != "any" else prefs.shape;
    climb_weight = 0.0;
    if prefs.avoid_hills {
        climb_weight = 0.5;
    } elif request.level == "beginner" {
        climb_weight = 0.15;
    }
    return route_options(
        [lm.name for lm in landmarks],
        request.distance_km,
        3,
        seed,
        request.start if request.start != "" else None,
        shape,
        preference_bonus(landmarks, prefs),
        climb_weight
    );
}

"""Plan a route for a validated request, retrying once if the check fails.

Code reads the notes into preferences (through the LLM), measures candidate
routes that fit them, and the LLM picks one and describes it.
"""
def generate_route(
    request: RunRequest,
    planner: Planner = plan_route,
    seed: int | None = None,
    pref_parser: PrefParser = parse_notes
) -> RouteResult | None {
    landmarks = landmarks_for_request(request);
    prefs = preferences_for(request, pref_parser);
    options = options_for(request, landmarks, prefs, seed);
    if len(options) == 0 {
        return None;
    }
    for _ in range(2) {
        pick = planner(request, landmarks, options);
        route = build_route(pick, options, landmarks);
        if route is not None and check_route(route, landmarks) == [] {
            return route;
        }
    }
    return None;
}

"""Routes from the picks that pass the check, one per option, in the picks' order.

A pick that names a missing option, repeats an option already used, or fails
the check is dropped.
"""
def valid_routes(
    picks: list[RoutePick], options: list[RouteOption], landmarks: list[Landmark]
) -> list[RouteResult] {
    routes: list[RouteResult] = [];
    used: list[int] = [];
    for pick in picks {
        if pick.option in used {
            continue;
        }
        route = build_route(pick, options, landmarks);
        if route is None or check_route(route, landmarks) != [] {
            continue;
        }
        used.append(pick.option);
        routes.append(route);
    }
    return routes;
}

"""Plan up to three routes for a validated request, retrying once if none passes.

Code reads the notes into preferences (through the LLM) and measures the
candidate routes; one LLM call then describes every candidate, best fit
first, so the runner can choose.
"""
def generate_routes(
    request: RunRequest,
    planner: ChoicePlanner = plan_routes,
    seed: int | None = None,
    pref_parser: PrefParser = parse_notes
) -> list[RouteResult] {
    landmarks = landmarks_for_request(request);
    prefs = preferences_for(request, pref_parser);
    options = options_for(request, landmarks, prefs, seed);
    if len(options) == 0 {
        return [];
    }
    for _ in range(2) {
        choices = planner(request, landmarks, options);
        routes = valid_routes(choices.picks, options, landmarks);
        if len(routes) > 0 {
            return routes;
        }
    }
    return [];
}
