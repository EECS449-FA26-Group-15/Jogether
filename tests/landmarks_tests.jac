import from landmarks { landmarks_for }
import from routes { example_route }

test "each area has 14 to 20 landmarks" {
    for area in ["central-campus", "north-campus", "downtown"] {
        assert 14 <= len(landmarks_for(area)) <= 20;
    }
}

test "unknown areas have no landmarks" {
    assert landmarks_for("anywhere") == [];
}

test "example route uses central campus landmarks" {
    names = [landmark.name for landmark in landmarks_for("central-campus")];
    route = example_route();
    for waypoint in route.waypoints {
        assert waypoint.name in names;
    }
    assert 1 <= route.difficulty <= 5;
    assert len(route.safety_notes) <= 3;
}
