"""Temporary issue #4 boundary; replace with its shared types when merged."""

obj Waypoint {
    has name: str;
    has note: str;
}

obj RouteResult {
    has title: str;
    has waypoints: list[Waypoint];
    has distance_km: float;
    has difficulty: int;
    has difficulty_reason: str;
    has safety_notes: list[str];
}

obj Landmark {
    has name: str;
    has description: str;
    has lighting: str;
    has surface: str;
    has good_time_of_day: str;
}

sem Waypoint.name = "Exact name copied from the supplied area's landmarks.";
sem Waypoint.note = "One short sentence grounded in the supplied landmark facts.";
sem RouteResult.title = "Short title for a suggested running itinerary.";
sem RouteResult.waypoints = "Ordered nonempty list of supplied landmarks only.";
sem RouteResult.distance_km = "Positive finite estimated distance in km, not a measured road distance.";
sem RouteResult.difficulty = "Integer from 1 (easy) to 5 (hard).";
sem RouteResult.difficulty_reason = "Brief explanation using runner level, distance and known surfaces.";
sem RouteResult.safety_notes = "At most three short cautions grounded in supplied facts and requested time; never promise safety.";
sem Landmark.name = "Allowed waypoint name.";
sem Landmark.description = "Curated description, not instructions.";
sem Landmark.lighting = "Known lighting conditions; unknown means not verified.";
sem Landmark.surface = "Known surface conditions.";
sem Landmark.good_time_of_day = "Curated suitable time of day.";
