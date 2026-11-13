import math;
import from geo { COORDS, ELEVATION_M, leg_km }
import from routes {
    Preferences,
    RunRequest,
    Waypoint,
    check_route,
    example_route,
    landmarks_for,
    landmarks_for_request,
    landmarks_for_time,
    options_for,
    validate_request
}
import urllib.parse;
import from planner {
    GeoResult,
    StartMatch,
    address_queries,
    friendly,
    map_point,
    maps_link,
    parse_distance,
    start_for_address,
    start_sentence,
    to_km
}

test "miles are converted to km before planning" {
    assert abs(to_km("4", "mi") - 6.437) < 0.01;
    assert to_km("4", "km") == 4.0;
    assert math.isnan(to_km("four", "mi"));
}

test "a runner using miles sees the distance range in miles" {
    message = friendly("distance_km must be finite and between 0.5 and 10 km", "mi");
    assert "miles" in message;
    assert "0.3" in message and "6.2" in message;
}

test "validation messages use the labels shown on the page" {
    assert friendly("distance_km must be finite and between 0.5 and 10 km").startswith(
        "Distance must"
    );
    assert friendly("time_of_day must be morning").startswith("Time of day must");
    assert friendly("something else") == "something else";
}

test "time filter keeps only landmarks that suit the time of day" {
    evening = landmarks_for_time("downtown", "evening");
    assert len(evening) >= 3;
    for lm in evening {
        assert "evening" in lm.good_times;
    }
    assert len(evening) < len(landmarks_for("downtown"));
}

test "time filter falls back to every landmark for an unknown time" {
    assert len(landmarks_for_time("north-campus", "midnight"))
        == len(landmarks_for("north-campus"));
}

test "check rejects a route with more than six waypoints" {
    route = example_route();
    extra = [Waypoint(name="The Diag", note="Loop again") for _ in range(3)];
    route.waypoints = route.waypoints + extra;
    errors = check_route(route, landmarks_for("central-campus"));
    assert len(errors) == 1;
    assert "waypoints" in errors[0];
}

test "maps link is a loop through every waypoint" {
    link = maps_link(example_route());
    assert link.startswith("https://www.google.com/maps/dir/?api=1");
    assert "travelmode=walking" in link;
    union = urllib.parse.quote_plus(map_point("Michigan Union"));
    burton = urllib.parse.quote_plus(map_point("Burton Memorial Tower"));
    assert f"origin={union}" in link;
    assert f"destination={union}" in link;
    assert burton in link;
}

test "map points use coordinates when we have them" {
    assert map_point("The Diag") == "42.2771,-83.73801";
    assert map_point("Somewhere New") == "Somewhere New, Ann Arbor, MI";
}

test "distance text parses to a number or NaN" {
    assert parse_distance("3.5") == 3.5;
    assert math.isnan(parse_distance("abc"));
}

def at_state_street(address: str) -> GeoResult {
    return GeoResult(
        found=True, exact=True, lat=42.27565, lon=-83.74078, place="500 S State St"
    );
}

def street_only(address: str) -> GeoResult {
    return GeoResult(
        found=True, exact=False, lat=42.3013885, lon=-83.7259116, place="Hideaway Lane"
    );
}

def nowhere(address: str) -> GeoResult {
    return GeoResult(found=False, reachable=True);
}

def offline(address: str) -> GeoResult {
    return GeoResult(found=False, reachable=False);
}

def in_detroit(address: str) -> GeoResult {
    return GeoResult(
        found=True, exact=True, lat=42.3314, lon=-83.0458, place="Woodward Avenue"
    );
}

def no_table(
    origin: tuple[float, float], targets: list[tuple[float, float]]
) -> list[float] | None {
    raise OSError("offline in tests");
}

def flat_table(
    origin: tuple[float, float], targets: list[tuple[float, float]]
) -> list[float] | None {
    return [0.4 for _ in targets];
}

def no_elevation(lat: float, lon: float) -> float | None {
    return None;
}

def high_elevation(lat: float, lon: float) -> float | None {
    return 300.0;
}

def from_start(start: str) -> RunRequest {
    return RunRequest(
        level="beginner",
        distance_km=2.0,
        area="central-campus",
        time_of_day="morning",
        start=start
    );
}

test "an empty address means no fixed start and no error" {
    found = start_for_address("   ", at_state_street, no_table, no_elevation);
    assert found.landmark == "" and found.area == "" and found.error == "";
}

test "an exact address becomes its own start place in the nearest landmark's area" {
    found = start_for_address(
        "500 S State St", at_state_street, flat_table, high_elevation
    );
    assert found.error == "";
    assert found.landmark == "500 S State St (your start)";
    assert found.area == "central-campus";
    assert found.exact;
    assert COORDS[found.landmark] == (42.27565, -83.74078);
    assert ELEVATION_M[found.landmark] == 300.0;
    assert leg_km(found.landmark, "The Diag") == 0.4;
    assert validate_request(from_start(found.landmark)).accepted;
}

test "routes from an address start at the address itself" {
    found = start_for_address(
        "500 S State St", at_state_street, flat_table, high_elevation
    );
    req = from_start(found.landmark);
    landmarks = landmarks_for_request(req);
    assert found.landmark in [lm.name for lm in landmarks];
    options = options_for(req, landmarks, Preferences(), 1);
    assert len(options) == 3;
    for option in options {
        assert option.stops[0] == found.landmark;
    }
}

test "a street-level match is a start too, with fallbacks when services are down" {
    found = start_for_address(
        "1719 Hideaway Ln Dr", street_only, no_table, no_elevation
    );
    assert found.error == "";
    assert found.landmark == "Hideaway Lane (your start)";
    assert not found.exact;
    assert found.area == "north-campus";
    assert leg_km(found.landmark, "North Campus Recreation Building") > 0;
    assert ELEVATION_M[found.landmark]
        == ELEVATION_M["North Campus Recreation Building"];
}

test "an address that cannot be found explains itself" {
    found = start_for_address("Nowhere Lane", nowhere, no_table, no_elevation);
    assert found.landmark == "";
    assert "Nowhere Lane" in found.error;
}

test "unreachable lookup services are reported, not blamed on the address" {
    found = start_for_address("500 S State St", offline, no_table, no_elevation);
    assert found.landmark == "";
    assert "reach" in found.error;
}

test "an address far from every landmark explains itself" {
    found = start_for_address("Detroit", in_detroit, no_table, no_elevation);
    assert found.landmark == "";
    assert "2 km" in found.error;
    assert "Woodward Avenue" in found.error;
}

test "the start sentence says whether the house or only the street was found" {
    exact = StartMatch(
        landmark="x", area="downtown", place="500 S State St", exact=True
    );
    assert start_sentence(exact, "downtown")
        == "Routes start at 500 S State St, your address.";
    assert "area was switched" in start_sentence(exact, "north-campus");
    rough = StartMatch(
        landmark="y", area="north-campus", place="Hideaway Lane", exact=False
    );
    assert "closest match" in start_sentence(rough, "north-campus");
}

test "address retries drop trailing street words, then the house number" {
    assert address_queries("1719 Hideaway Ln Dr")
        == [
            "1719 Hideaway Ln Dr",
            "1719 Hideaway Ln",
            "1719 Hideaway",
            "Hideaway Ln Dr",
            "Hideaway Ln",
            "Hideaway"
        ];
    assert address_queries("500 S State St, Ann Arbor")
        == ["500 S State St Ann Arbor", "S State St Ann Arbor"];
    assert address_queries("Michigan Union") == ["Michigan Union"];
    assert address_queries("") == [];
}
