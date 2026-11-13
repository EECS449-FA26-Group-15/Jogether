import math;
import from routes {
    Waypoint,
    check_route,
    example_route,
    landmarks_for,
    landmarks_for_time
}
import urllib.parse;
import from planner {
    GeoResult,
    address_queries,
    friendly,
    map_point,
    maps_link,
    parse_distance,
    start_for_address,
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

def at_diag(address: str) -> GeoResult {
    return GeoResult(found=True, lat=42.2771, lon=-83.73801, place="State Street");
}

def nowhere(address: str) -> GeoResult {
    return GeoResult(found=False, reachable=True);
}

def offline(address: str) -> GeoResult {
    return GeoResult(found=False, reachable=False);
}

def in_detroit(address: str) -> GeoResult {
    return GeoResult(found=True, lat=42.3314, lon=-83.0458, place="Woodward Avenue");
}

test "an empty address means no fixed start and no error" {
    found = start_for_address("   ", at_diag);
    assert found.landmark == "" and found.area == "" and found.error == "";
}

test "an address becomes the nearest landmark and its area" {
    found = start_for_address("500 S State St", at_diag);
    assert found.landmark == "The Diag";
    assert found.area == "central-campus";
    assert found.place == "State Street";
    assert found.error == "";
}

test "an address that cannot be found explains itself" {
    found = start_for_address("Nowhere Lane", nowhere);
    assert found.landmark == "";
    assert "Nowhere Lane" in found.error;
}

test "an unreachable lookup service is reported, not blamed on the address" {
    found = start_for_address("500 S State St", offline);
    assert found.landmark == "";
    assert "reach" in found.error;
}

test "an address far from every landmark explains itself" {
    found = start_for_address("Detroit", in_detroit);
    assert found.landmark == "";
    assert "2 km" in found.error;
    assert "Woodward Avenue" in found.error;
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
