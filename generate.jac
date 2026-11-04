"""Explicit real-model CLI; requires a user-supplied curated landmark file."""

import argparse;
import json;
import sys;
import from jaclang.byllm.exceptions { ByLLMError }
import from routes { RunRequest }
import from route_agent { generate_route }
import from landmark_data { load_landmarks }
import from route_contract { RouteResult }

def route_payload(result: RouteResult) -> dict[str, object] {
    return {
        "title": result.title,
        "waypoints": [
            {"name": point.name, "note": point.note} for point in result.waypoints
        ],
        "distance_km": result.distance_km,
        "difficulty": result.difficulty,
        "difficulty_reason": result.difficulty_reason,
        "safety_notes": result.safety_notes
    };
}

def main {
    parser = argparse.ArgumentParser(
        description="Generate an estimated route suggestion with local Ollama."
    );
    parser.add_argument("--landmarks", required=True);
    parser.add_argument("--level", `default="beginner");
    parser.add_argument("--distance-km", type=float, `default=2.0);
    parser.add_argument("--area", `default="central-campus");
    parser.add_argument("--time-of-day", `default="morning");
    args = parser.parse_args();
    try {
        result = generate_route(
            request=RunRequest(
                level=args.level,
                distance_km=args.distance_km,
                area=args.area,
                time_of_day=args.time_of_day
            ),
            areas=load_landmarks(args.landmarks)
        );
        print(json.dumps(route_payload(result), indent=2, allow_nan=False));
    } except (ValueError, OSError, ByLLMError) as error {
        print(str(error), file=sys.stderr);
        sys.exit(2);
    }
}

with entry:__main__ {
    main();
}
