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
