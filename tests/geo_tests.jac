import from geo { COORDS, leg_km, loop_km, route_options }
import from landmarks { landmarks_for }

def names(area: str) -> list[str] {
    return [lm.name for lm in landmarks_for(area)];
}

test "every landmark has coordinates" {
    for area in ["central-campus", "north-campus", "downtown"] {
        for name in names(area) {
            assert name in COORDS , f"no coordinates for {name}";
        }
    }
}

test "Diag to Union is a short walk" {
    assert 0.3 <= leg_km("The Diag", "Michigan Union") <= 0.7;
}

test "options land near the requested distance" {
    for target in [2.0, 4.0] {
        options = route_options(names("north-campus"), target, 3, seed=1);
        assert len(options) == 3;
        for option in options {
            assert abs(option.distance_km - target) <= 1.0 , f"{option.distance_km} vs {target}";
        }
    }
}

test "different distances give different routes" {
    short = route_options(names("central-campus"), 1.5, 1, seed=1)[0];
    long = route_options(names("central-campus"), 4.5, 1, seed=1)[0];
    assert set(short.stops) != set(long.stops);
    assert long.distance_km > short.distance_km;
}

test "long runs repeat a loop" {
    option = route_options(names("downtown"), 10.0, 1, seed=1)[0];
    assert option.laps >= 2;
    assert abs(option.distance_km - option.loop_km * option.laps) < 0.2;
}

test "options use different sets of stops" {
    options = route_options(names("downtown"), 3.0, 3, seed=1);
    sets = [set(o.stops) for o in options];
    assert sets[0] != sets[1] and sets[1] != sets[2] and sets[0] != sets[2];
}

test "loop length closes back to the start" {
    stops = ["The Diag", "Michigan Union", "Law Quadrangle"];
    expected = leg_km(stops[0], stops[1])
        + leg_km(stops[1], stops[2])
        + leg_km(stops[2], stops[0]);
    assert abs(loop_km(stops) - expected) < 1e-9;
}
