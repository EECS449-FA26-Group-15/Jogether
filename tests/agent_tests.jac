import from unittest.mock { patch }
import from jaclang.byllm.lib { MockLLM }
import from jaclang.byllm.exceptions { ModelNotFoundError }
import route_agent;
import from route_agent { GenerateRoute, generate_route, route_errors }
import from route_contract { Landmark, RouteResult, Waypoint }
import from routes { RunRequest }
import io;
import json;
import from contextlib { redirect_stdout }
import from generate { main }

def request -> RunRequest {
    return RunRequest(
        level="beginner", distance_km=2.0, area="central-campus", time_of_day="morning"
    );
}

def areas -> dict[str, list[Landmark]] {
    return {
        "central-campus": [
            Landmark(
                name="TEST Central A",
                description="Fictional test fixture",
                lighting="unknown",
                surface="paved",
                good_time_of_day="morning"
            )
        ],
        "north-campus": [
            Landmark(
                name="TEST North B",
                description="Fictional test fixture",
                lighting="unknown",
                surface="gravel",
                good_time_of_day="afternoon"
            )
        ]
    };
}

def valid_route -> RouteResult {
    return RouteResult(
        title="Test itinerary",
        waypoints=[Waypoint(name="TEST Central A", note="Test fixture only")],
        distance_km=2.0,
        difficulty=1,
        difficulty_reason="Short test route",
        safety_notes=["Lighting is unknown"]
    );
}

test "walker reports a typed route and only selected area reaches model" {
    mock = MockLLM(outputs=[valid_route()]);
    with patch.object(route_agent, "llm", mock) {
        result = root spawn GenerateRoute(request=request(), areas=areas());
        assert len(result.reports) == 1;
        assert result.reports[0].title == "Test itinerary";
    }
    assert len(mock.seen) == 1;
    prompt = str(mock.sent("messages")[0]);
    assert "TEST Central A" in prompt;
    assert "TEST North B" not in prompt;
}

test "invalid waypoint gets exactly one retry with corrective feedback" {
    bad = valid_route();
    bad.waypoints[0].name = "TEST North B";
    mock = MockLLM(outputs=[bad, valid_route()]);
    with patch.object(route_agent, "llm", mock) {
        assert generate_route(request(), areas()).waypoints[0].name == "TEST Central A";
    }
    assert len(mock.seen) == 2;
    assert "unknown waypoint" in str(mock.sent("messages")[1]);
}

test "two invalid results fail without a third call" {
    bad = valid_route();
    bad.difficulty = 6;
    mock = MockLLM(outputs=[bad, bad, valid_route()]);
    with patch.object(route_agent, "llm", mock) {
        with testraises(ValueError, `match="after 2 attempts") {
            generate_route(request(), areas());
        }
    }
    assert len(mock.seen) == 2;
}

test "malformed model output can recover with one retry" {
    mock = MockLLM(outputs=["not valid structured output", valid_route()]);
    with patch.object(route_agent, "llm", mock) {
        assert generate_route(request(), areas()).difficulty == 1;
    }
    assert len(mock.seen) == 2;
}

test "two malformed outputs fail within the shared retry budget" {
    mock = MockLLM(outputs=["bad", "bad", valid_route()]);
    with patch.object(route_agent, "llm", mock) {
        with testraises(ValueError, `match="after 2 attempts") {
            generate_route(request(), areas());
        }
    }
    assert len(mock.seen) == 2;
}

test "invalid input or missing data never calls the model" {
    mock = MockLLM(outputs=[]);
    with patch.object(route_agent, "llm", mock) {
        invalid = request();
        invalid.distance_km = 0.0;
        with testraises(ValueError, `match="Invalid RunRequest") {
            generate_route(invalid, areas());
        }
        with testraises(ValueError, `match="No landmark data") {
            generate_route(request(), {});
        }
    }
    assert len(mock.seen) == 0;
}

test "validator enforces difficulty safety count and finite distance" {
    landmarks = areas()["central-campus"];
    for difficulty in [1, 5] {
        result = valid_route();
        result.difficulty = difficulty;
        result.safety_notes = ["one", "two", "three"];
        assert route_errors(result, landmarks) == [];
    }
    for difficulty in [0, 6] {
        result = valid_route();
        result.difficulty = difficulty;
        assert route_errors(result, landmarks);
    }
    result = valid_route();
    result.safety_notes = ["one", "two", "three", "four"];
    assert route_errors(result, landmarks);
    for distance in [0.0, -1.0, float("nan"), float("inf")] {
        result = valid_route();
        result.distance_km = distance;
        assert route_errors(result, landmarks);
    }
    result = valid_route();
    result.waypoints = [];
    assert route_errors(result, landmarks);
}

test "provider failures propagate without generating a fallback route" {
    mock = MockLLM(outputs=[]);
    with patch.object(route_agent, "llm", mock) {
        with patch.object(
            mock, "invoke", side_effect=ModelNotFoundError("model missing")
        ) as call {
            with testraises(ModelNotFoundError) {
                generate_route(request(), areas());
            }
            assert call.call_count == 1;
        }
    }
}

test "generation CLI prints JSON after typed model parsing" {
    mock = MockLLM(outputs=[valid_route()]);
    output = io.StringIO();
    with patch.object(route_agent, "llm", mock) {
        with patch("generate.load_landmarks", return_value=areas()) {
            with patch("sys.argv", ["generate.jac", "--landmarks", "fixture.json"]) {
                with redirect_stdout(output) {
                    main();
                }
            }
        }
    }
    payload = json.loads(output.getvalue());
    assert payload["title"] == "Test itinerary";
    assert payload["waypoints"][0]["name"] == "TEST Central A";
    assert payload["difficulty"] == 1;
    assert len(mock.seen) == 1;
}
