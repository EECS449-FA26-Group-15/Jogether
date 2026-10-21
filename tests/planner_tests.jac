import math;
import from routes {
    Waypoint,
    check_route,
    example_route,
    landmarks_for,
    landmarks_for_time
}
import from planner { friendly, maps_link, parse_distance }

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

test "maps link walks through every waypoint in order" {
    link = maps_link(example_route());
    assert link.startswith("https://www.google.com/maps/dir/?api=1");
    assert "travelmode=walking" in link;
    assert "Michigan+Union" in link;
    assert "Burton+Memorial+Tower" in link;
}

test "distance text parses to a number or NaN" {
    assert parse_distance("3.5") == 3.5;
    assert math.isnan(parse_distance("abc"));
}
