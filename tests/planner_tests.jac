import math;
import from routes {
    Waypoint,
    check_route,
    example_route,
    landmarks_for,
    landmarks_for_time
}
import urllib.parse;
import from planner { friendly, map_point, maps_link, parse_distance }

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
