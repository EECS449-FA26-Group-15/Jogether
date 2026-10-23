"""Validate the four MVP answers and plan a route from known landmarks."""

import math;
import from landmarks { Landmark, landmarks_for }
import from geo { RouteOption, loop_km, route_options }

obj RunRequest {
    has level: str,
        distance_km: float,
        area: str,
        time_of_day: str,
        notes: str = "";
}

obj ValidationResult {
    has accepted: bool,
        errors: list[str],
        request: RunRequest;
}

def validate_request(request: RunRequest) -> ValidationResult {
    errors: list[str] = [];
    if request.level not in ["beginner", "intermediate", "experienced"] {
        errors.append("level must be beginner, intermediate, or experienced");
    }
    if not math.isfinite(request.distance_km)
        or not (0.5 <= request.distance_km <= 10.0) {
        errors.append("distance_km must be finite and between 0.5 and 10 km");
    }
    if request.area not in ["central-campus", "north-campus", "downtown"] {
        errors.append("area must be central-campus, north-campus, or downtown");
    }
    if request.time_of_day not in ["morning", "afternoon", "evening"] {
        errors.append("time_of_day must be morning, afternoon, or evening");
    }
    return ValidationResult(accepted=len(errors) == 0, errors=errors, request=request);
}

"""One stop on a route, named after a landmark from landmarks.jac."""
obj Waypoint {
    has name: str,
        note: str;
}

"""The route shape shared by the route agent and the result page.

`distance_km` is measured by code from landmark coordinates (see geo.jac):
one loop through the waypoints and back to the first one, times `laps`.
"""
obj RouteResult {
    has title: str,
        waypoints: list[Waypoint],
        distance_km: float,
        difficulty: int,
        difficulty_reason: str,
        safety_notes: list[str],
        laps: int = 1;
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
sem Waypoint.name = "Exact name of a landmark from the given list";
sem Waypoint.note = "One line on what the runner sees or does here";
sem RoutePick.option = "0-based index of the chosen option in the options list";
sem RoutePick.title = "Short route name that matches the chosen stops; do not mention places that are not on the route";
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

Each option is a loop that is already measured: run its stops in order, return
to the first stop, and repeat for its laps. Pick the option whose stops best
match the runner's level, time of day and own words (notes), using the landmark
descriptions, lighting and surfaces. Do not change, add or reorder stops. Rate
difficulty from the option's distance, laps, the runner's level and the
surfaces. Base safety notes on the chosen stops' lighting and the time of day.
"""
def plan_route(
    request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
) -> RoutePick by llm();

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
        laps=chosen.laps
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
    for waypoint in route.waypoints {
        if waypoint.name not in names {
            errors.append(f"unknown landmark: {waypoint.name}");
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
     MAX_WAYPOINTS: int = 6;

"""Landmarks in an area that suit the time of day, or all of them if fewer than 3 do."""
def landmarks_for_time(area: str, time_of_day: str) -> list[Landmark] {
    all_landmarks = landmarks_for(area);
    suitable = [
        lm
        for lm in all_landmarks
        if time_of_day in lm.good_times
    ];
    return suitable if len(suitable) >= 3 else all_landmarks;
}

"""Landmarks for this request: right for the time of day, and no dirt trails for beginners."""
def landmarks_for_request(request: RunRequest) -> list[Landmark] {
    landmarks = landmarks_for_time(request.area, request.time_of_day);
    if request.level == "beginner" {
        easier = [
            lm
            for lm in landmarks
            if lm.surface != "dirt trail"
        ];
        if len(easier) >= 3 {
            return easier;
        }
    }
    return landmarks;
}

"""Plan a route for a validated request, retrying once if the check fails.

Code measures candidate loops near the requested distance; the LLM picks one
and describes it.
"""
def generate_route(
    request: RunRequest, planner: Planner = plan_route, seed: int | None = None
) -> RouteResult | None {
    landmarks = landmarks_for_request(request);
    options = route_options(
        [lm.name for lm in landmarks], request.distance_km, 3, seed
    );
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
