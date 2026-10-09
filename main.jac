"""Local four-question demo. This does not generate a real route."""

import argparse;
import json;
import math;
import sys;
import from routes { RunRequest, validate_request }

with entry {
    parser = argparse.ArgumentParser(
        description="Preview a Jogether run request (no route generation yet)."
    );
    parser.add_argument("--level", `default="beginner");
    parser.add_argument("--distance-km", type=float, `default=2.0);
    parser.add_argument("--area", `default="central-campus");
    parser.add_argument("--time-of-day", `default="morning");
    args = parser.parse_args();
    request = RunRequest(
        level=args.level,
        distance_km=args.distance_km,
        area=args.area,
        time_of_day=args.time_of_day
    );
    result = validate_request(request);
    print(
        json.dumps(
            {
                "accepted": result.accepted,
                "errors": result.errors,
                "request": {
                    "level": result.request.level,
                    "distance_km": result.request.distance_km
                        if math.isfinite(result.request.distance_km)
                        else None,
                    "area": result.request.area,
                    "time_of_day": result.request.time_of_day
                },
                "route_generated": False
            },
            indent=2,
            allow_nan=False
        )
    );
    if not result.accepted {
        sys.exit(2);
    }
}
