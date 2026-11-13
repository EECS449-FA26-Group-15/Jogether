import from jaclang.byllm.lib { MockLLM }
import from geo { RouteOption }
import from landmarks { Landmark, landmarks_for }
import from routes {
    Preferences,
    RouteChoices,
    RoutePick,
    RunRequest,
    Waypoint,
    code_difficulty,
    generate_routes,
    landmarks_for_request,
    options_for,
    valid_routes
}

def request(start: str = "") -> RunRequest {
    return RunRequest(
        level="intermediate",
        distance_km=3.0,
        area="downtown",
        time_of_day="morning",
        start=start
    );
}

def pick(option: int, title: str = "Morning run") -> RoutePick {
    return RoutePick(
        option=option,
        title=title,
        stops=[],
        difficulty=2,
        difficulty_reason="Flat and short",
        safety_notes=["Watch the crossings"]
    );
}

def no_prefs(text: str) -> Preferences {
    return Preferences();
}

test "valid routes keep one route per option in the picks' order" {
    req = request();
    landmarks = landmarks_for_request(req);
    options = options_for(req, landmarks, Preferences(), 1);
    assert len(options) == 3;
    picks = [pick(2, "River first"), pick(0), pick(2, "Again"), pick(9)];
    routes = valid_routes(picks, options, landmarks);
    assert len(routes) == 2;
    assert routes[0].title == "River first";
    assert [w.name for w in routes[0].waypoints] == options[2].stops;
    assert [w.name for w in routes[1].waypoints] == options[0].stops;
}

test "a pick whose title names a place off the route is dropped" {
    req = request();
    landmarks = landmarks_for_request(req);
    options = options_for(req, landmarks, Preferences(), 1);
    off_route = [
        lm.name
        for lm in landmarks
        if lm.name not in options[0].stops
    ][0];
    bad = pick(0, f"Sprint to {off_route}");
    assert valid_routes([bad, pick(1)], options, landmarks)[0].title == "Morning run";
    assert len(valid_routes([bad], options, landmarks)) == 0;
}

test "an out-of-range difficulty is replaced by the code estimate, extra safety notes are cut" {
    req = request();
    landmarks = landmarks_for_request(req);
    options = options_for(req, landmarks, Preferences(), 1);
    wild = pick(0);
    wild.difficulty = 9;
    wild.safety_notes = ["one", "two", "three", "four"];
    tame = pick(1);
    tame.difficulty = 0;
    routes = valid_routes([wild, tame], options, landmarks, "beginner");
    assert len(routes) == 2;
    assert routes[0].difficulty == code_difficulty(options[0], "beginner");
    assert 1 <= routes[0].difficulty <= 3;
    assert routes[0].safety_notes == ["one", "two", "three"];
    assert routes[1].difficulty == code_difficulty(options[1], "beginner");
}

test "the code estimate grows with distance and climb and drops with experience" {
    short = RouteOption(stops=["a", "b", "c"], laps=1, loop_km=2.0, distance_km=2.0);
    long = RouteOption(stops=["a", "b", "c"], laps=1, loop_km=9.5, distance_km=9.5);
    hilly = RouteOption(
        stops=["a", "b", "c"], laps=1, loop_km=5.0, distance_km=5.0, climb_m=95.0
    );
    assert code_difficulty(short, "beginner") == 1;
    assert code_difficulty(long, "beginner") == 5;
    assert code_difficulty(hilly, "beginner") == 5;
    assert code_difficulty(hilly, "intermediate") == 4;
    assert code_difficulty(hilly, "experienced") == 4;
    assert code_difficulty(short, "experienced") == 1;
}

test "three routes come back from one mocked call, all starting at the chosen start" {
    mock = MockLLM(
        outputs=[RouteChoices(picks=[pick(0), pick(1, "Second"), pick(2, "Third")])]
    );
    def plan(
        req: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RouteChoices by mock();
    routes = generate_routes(request(start="Main Street"), plan, 1, no_prefs);
    assert len(routes) == 3;
    assert [r.title for r in routes] == ["Morning run", "Second", "Third"];
    for route in routes {
        assert route.waypoints[0].name == "Main Street";
        assert route.distance_km > 0;
    }
    assert len(set([tuple([w.name for w in r.waypoints]) for r in routes])) == 3;
    assert len(mock.seen_prompts) == 1;
}

test "the planner is asked once more when nothing passes, then gives up" {
    calls: list[int] = [];
    def nothing_useful(
        req: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RouteChoices {
        calls.append(1);
        return RouteChoices(picks=[pick(7), pick(8)]);
    }
    assert generate_routes(request(), nothing_useful, 1, no_prefs) == [];
    assert len(calls) == 2;
}

test "one good pick is enough to stop retrying" {
    calls: list[int] = [];
    def one_good(
        req: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RouteChoices {
        calls.append(1);
        return RouteChoices(picks=[pick(5), pick(1)]);
    }
    routes = generate_routes(request(), one_good, 1, no_prefs);
    assert len(routes) == 1;
    assert len(calls) == 1;
}
