import from jaclang.byllm.lib { MockLLM }
import from geo { RouteOption }
import from landmarks { Landmark, landmarks_for }
import from routes {
    Preferences,
    RouteChoices,
    RoutePick,
    RunRequest,
    Waypoint,
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

test "a pick that fails the check is dropped" {
    req = request();
    landmarks = landmarks_for_request(req);
    options = options_for(req, landmarks, Preferences(), 1);
    bad = pick(0);
    bad.difficulty = 9;
    assert valid_routes([bad, pick(1)], options, landmarks)[0].difficulty == 2;
    assert len(valid_routes([bad], options, landmarks)) == 0;
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
