"""Local four-question demo. Add --generate to plan a route with the LLM."""

import argparse;
import json;
import math;
import sys;
import from routes { RouteResult, RunRequest, generate_route, validate_request }

def route_json(route: RouteResult) -> dict[str, any] {
    return {
        "title": route.title,
        "waypoints": [{"name": w.name, "note": w.note} for w in route.waypoints],
        "distance_km": route.distance_km,
        "difficulty": route.difficulty,
        "difficulty_reason": route.difficulty_reason,
        "safety_notes": route.safety_notes
    };
}

with entry {
    parser = argparse.ArgumentParser(description="Preview or plan a Jogether run.");
    parser.add_argument("--level", `default="beginner");
    parser.add_argument("--distance-km", type=float, `default=2.0);
    parser.add_argument("--area", `default="central-campus");
    parser.add_argument("--time-of-day", `default="morning");
    parser.add_argument("--generate", action="store_true");
    args = parser.parse_args();
    request = RunRequest(
        level=args.level,
        distance_km=args.distance_km,
        area=args.area,
        time_of_day=args.time_of_day
    );
    result = validate_request(request);
    route = generate_route(request) if result.accepted and args.generate else None;
    errors = result.errors;
    if result.accepted and args.generate and route is None {
        errors = ["no route passed the output check after one retry"];
    }
    print(
        json.dumps(
            {
                "accepted": result.accepted,
                "errors": errors,
                "request": {
                    "level": result.request.level,
                    "distance_km": result.request.distance_km
                        if math.isfinite(result.request.distance_km)
                        else None,
                    "area": result.request.area,
                    "time_of_day": result.request.time_of_day
                },
                "route_generated": route is not None,
                "route": route_json(route) if route is not None else None
            },
            indent=2,
            allow_nan=False
        )
    );
    if not result.accepted {
        sys.exit(2);
    }
    if args.generate and route is None {
        sys.exit(1);
    }
}
