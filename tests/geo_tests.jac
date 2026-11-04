import from geo {
    COORDS,
    RouteOption,
    WALK_KM,
    climb_m,
    leg_km,
    loop_km,
    path_km,
    route_options
}
import from landmarks { all_landmarks, landmarks_for }

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

test "a 4 mile request is one big loop when the area has one" {
    for area in ["central-campus", "north-campus", "downtown"] {
        for option in route_options(names(area), 6.4, 3, seed=1) {
            assert option.laps <= 2 , f"{area}: {option.laps} laps";
            assert option.loop_km >= 2.5 , f"{area}: loop only {option.loop_km} km";
        }
    }
}

test "measured walking distances are used when we have them" {
    assert leg_km("The Diag", "Michigan Union") == WALK_KM["The Diag|Michigan Union"];
}

test "a long run in a big enough pool needs no laps" {
    everything = [lm.name for lm in all_landmarks()];
    for option in route_options(everything, 10.0, 3, seed=1, start="Main Street") {
        assert option.laps == 1 , f"{option.laps} laps";
        assert abs(option.distance_km - 10.0) <= 1.0;
    }
}

test "laps are only a fallback and still measure correctly" {
    option = route_options(names("downtown")[:5], 10.0, 1, seed=1)[0];
    assert option.laps >= 2;
    assert abs(option.distance_km - option.loop_km * option.laps) < 0.2;
}

test "a chosen start is the first stop of every option" {
    for option in route_options(
        names("central-campus"), 3.0, 3, seed=1, start="The Diag"
    ) {
        assert option.stops[0] == "The Diag";
    }
}

test "an unknown start gives no options" {
    assert route_options(names("central-campus"), 3.0, 3, start="Nowhere") == [];
}

test "shape filter is respected" {
    for shape in ["loop", "out-and-back", "one-way"] {
        options = route_options(names("downtown"), 3.0, 3, seed=1, shape=shape);
        assert len(options) > 0;
        for option in options {
            assert option.shape == shape;
        }
    }
}

test "out-and-back is twice the path and one-way is the path" {
    stops = ["The Diag", "Michigan Union", "Law Quadrangle"];
    assert abs(
        path_km(stops) - (leg_km(stops[0], stops[1]) + leg_km(stops[1], stops[2]))
    )
        < 1e-9;
    back = route_options(
        stops, 2 * path_km(stops), 1, shape="out-and-back", start="The Diag"
    )[0];
    assert abs(back.loop_km - 2 * path_km(back.stops)) < 0.02;
    one = route_options(stops, path_km(stops), 1, shape="one-way", start="The Diag")[0];
    assert abs(one.loop_km - path_km(one.stops)) < 0.02;
    assert one.laps == 1;
}

test "preference bonus pulls wanted landmarks into the route" {
    bonus = {"Argo Park": 2.0, "Bandemer Park": 2.0, "Argo Cascades": 2.0};
    plain = route_options(names("downtown"), 3.0, 3, seed=1, start="Main Street");
    river = route_options(
        names("downtown"), 3.0, 3, seed=1, start="Main Street", bonus=bonus
    );
    def river_stops(options: list[RouteOption]) -> int {
        return sum(
            [
                len(
                    [
                        s
                        for s in o.stops
                        if s in bonus
                    ]
                ) for o in options
            ]
        );
    }
    assert river_stops(river) > river_stops(plain);
}

test "climb is measured from elevation and penalised when asked" {
    assert climb_m(["Nichols Arboretum", "Observatory Street"], False) > 0;
    flat = route_options(names("central-campus"), 3.0, 1, seed=1, climb_weight=2.0)[0];
    hilly = route_options(names("central-campus"), 3.0, 1, seed=1, climb_weight=0.0)[0];
    assert flat.climb_m <= hilly.climb_m;
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
