"""Validate the four MVP answers before calling a route planner."""

import math;

obj RunRequest {
    has level: str;
    has distance_km: float;
    has area: str;
    has time_of_day: str;
}

obj ValidationResult {
    has accepted: bool;
    has errors: list[str];
    has request: RunRequest;
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
    has name: str;
    has note: str;
}

"""The route shape shared by the route agent and the result page."""
obj RouteResult {
    has title: str;
    has waypoints: list[Waypoint];
    has distance_km: float;
    has difficulty: int;
    has difficulty_reason: str;
    has safety_notes: list[str];
}

sem Waypoint.name = "Exact name of a landmark from the given list";
sem Waypoint.note = "One line on what the runner sees or does here";
sem RouteResult.distance_km = "Estimated route length in km";
sem RouteResult.difficulty = "1 (easiest) to 5 (hardest)";
sem RouteResult.safety_notes = "At most 3 notes for the chosen time of day";

"""Hand-written sample route for building the result page without an LLM."""
def example_route -> RouteResult {
    return RouteResult(
        title="Central campus starter loop",
        waypoints=[
            Waypoint(name="Michigan Union", note="Start on the State Street steps"),
            Waypoint(name="The Diag", note="Cut across the paved paths"),
            Waypoint(name="Ingalls Mall", note="Easy stretch along the lawn"),
            Waypoint(name="Burton Memorial Tower", note="Turn back toward State Street")
        ],
        distance_km=2.0,
        difficulty=1,
        difficulty_reason="Short, flat and paved, with plenty of places to stop",
        safety_notes=[
            "Watch for bikes and scooters crossing the Diag",
            "Cross State Street at the signals"
        ]
    );
}
