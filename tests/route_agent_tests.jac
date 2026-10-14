import from jaclang.byllm.lib { MockLLM }
import from routes {
    Landmark,
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

test "generate retries once and returns the passing route" {
    mock = MockLLM(outputs=[bad_route(), example_route()]);
    def plan(request: RunRequest, landmarks: list[Landmark]) -> RouteResult by mock();
    route = generate_route(campus_request(), plan);
    assert route is not None;
    assert route.difficulty == 1;
    assert "The Diag" in mock.seen_prompts[0];
    assert mock.exhausted();
}

test "generate gives up after two failed routes" {
    mock = MockLLM(outputs=[bad_route(), bad_route()]);
    def plan(request: RunRequest, landmarks: list[Landmark]) -> RouteResult by mock();
    assert generate_route(campus_request(), plan) is None;
}
