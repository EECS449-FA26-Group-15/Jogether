import from jaclang.byllm.lib { MockLLM }
import from geo { RouteOption }
import from routes {
    Landmark,
    RoutePick,
    RouteResult,
    RunRequest,
    Waypoint,
    check_route,
    example_route,
    generate_route,
    landmarks_for
}

def campus_request -> RunRequest {
    return RunRequest(
        level="beginner", distance_km=2.0, area="central-campus", time_of_day="morning"
    );
}

def bad_route -> RouteResult {
    route = example_route();
    route.difficulty = 0;
    return route;
}

test "check accepts the example route" {
    assert check_route(example_route(), landmarks_for("central-campus")) == [];
}

test "check rejects unknown landmarks bad difficulty and extra notes" {
    route = example_route();
    route.waypoints.append(Waypoint(name="Made Up Park", note="Not on the list"));
    route.difficulty = 6;
    route.safety_notes = ["one", "two", "three", "four"];
    assert len(check_route(route, landmarks_for("central-campus"))) == 3;
}

def pick(option: int, difficulty: int = 1) -> RoutePick {
    return RoutePick(
        option=option,
        title="Test loop",
        stops=[Waypoint(name="The Diag", note="Start on the paved square")],
        difficulty=difficulty,
        difficulty_reason="flat and short",
        safety_notes=["Cross at the signals"]
    );
}

test "generate retries once and returns the passing route" {
    mock = MockLLM(outputs=[pick(7), pick(0)]);
    def plan(
        request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RoutePick by mock();
    route = generate_route(campus_request(), plan, seed=1);
    assert route is not None;
    assert route.difficulty == 1;
    for w in route.waypoints {
        assert w.note.strip() != "" , f"{w.name} has no note";
        if w.name == "The Diag" {
            assert w.note == "Start on the paved square";
        }
    }
    assert "The Diag" in mock.seen_prompts[0];
    assert mock.exhausted();
}

test "generate gives up after two failed routes" {
    mock = MockLLM(outputs=[pick(7), pick(0, difficulty=9)]);
    def plan(
        request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RoutePick by mock();
    assert generate_route(campus_request(), plan, seed=1) is None;
}

test "route distance comes from the chosen option, not the LLM" {
    mock = MockLLM(outputs=[pick(0)]);
    def plan(
        request: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RoutePick by mock();
    request = campus_request();
    request.distance_km = 4.0;
    route = generate_route(request, plan, seed=1);
    assert route is not None;
    assert 3.0 <= route.distance_km * 1.0 <= 5.0;
    assert route.laps >= 1;
}
