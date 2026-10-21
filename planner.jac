"""Server endpoints the web page calls: plan a run, or fetch the example route."""

import time;
import traceback;
import urllib.parse;
import from geo { COORDS }
import from routes {
    RouteResult,
    RunRequest,
    example_route,
    generate_route,
    validate_request
}

"""What the page shows after the runner taps Generate."""
obj RunPlan {
    has accepted: bool,
        errors: list[str],
        route: RouteResult | None = None,
        maps_url: str = "",
        seconds: float = 0.0,
        is_example: bool = False;
}

"""A place Google Maps can find: our coordinates when we have them, else the name."""
def map_point(name: str) -> str {
    if name in COORDS {
        (lat, lon) = COORDS[name];
        return f"{lat},{lon}";
    }
    return f"{name}, Ann Arbor, MI";
}

"""Google Maps walking directions for one loop: through every waypoint and back to the start."""
def maps_link(route: RouteResult) -> str {
    stops = [map_point(w.name) for w in route.waypoints];
    if len(stops) < 2 {
        return "";
    }
    params: dict[str, str] = {
        "api": "1",
        "origin": stops[0],
        "destination": stops[0],
        "waypoints": "|".join(stops[1:]),
        "travelmode": "walking"
    };
    return "https://www.google.com/maps/dir/?" + urllib.parse.urlencode(params);
}

"""Turn the distance text from the form into a number; NaN fails validation."""
def parse_distance(text: str) -> float {
    try {
        return float(text);
    } except ValueError {
        return float("nan");
    }
}

"""Validation messages use field names; show the labels the runner sees instead."""
def friendly(error: str) -> str {
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

"""Validate the four answers, then ask the route agent for a route."""
def:pub plan_run(
    level: str, distance_km: str, area: str, time_of_day: str, notes: str
) -> RunPlan {
    request = RunRequest(
        level=level,
        distance_km=parse_distance(distance_km),
        area=area,
        time_of_day=time_of_day,
        notes=notes.strip()[:300]
    );
    checked = validate_request(request);
    if not checked.accepted {
        return RunPlan(accepted=False, errors=[friendly(e) for e in checked.errors]);
    }
    started = time.time();
    route: RouteResult | None = None;
    try {
        route = generate_route(request);
    } except Exception as err {
        traceback.print_exc();
        kind = type(err).__name__;
        return RunPlan(
            accepted=True,
            errors=[
                f"The route planner is not available right now ({kind}). Is Ollama running?"
            ],
            seconds=round(time.time() - started, 1)
        );
    }
    seconds = round(time.time() - started, 1);
    if route is None {
        return RunPlan(
            accepted=True,
            errors=[
                "The AI could not produce a route that passed our check. Try again or change your answers."
            ],
            seconds=seconds
        );
    }
    return RunPlan(
        accepted=True,
        errors=[],
        route=route,
        maps_url=maps_link(route),
        seconds=seconds
    );
}

"""The hand-written example route, clearly marked as not AI-generated."""
def:pub sample_run -> RunPlan {
    route = example_route();
    return RunPlan(
        accepted=True,
        errors=[],
        route=route,
        maps_url=maps_link(route),
        is_example=True
    );
}
