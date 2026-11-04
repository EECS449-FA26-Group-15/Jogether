import from jaclang.byllm.lib { MockLLM }
import from geo { RouteOption }
import from landmarks { Landmark, landmarks_for }
import from routes {
    Preferences,
    RoutePick,
    RouteResult,
    RunRequest,
    Waypoint,
    check_route,
    example_route,
    generate_route,
    landmarks_for_request,
    preference_bonus,
    preferences_for,
    validate_request
}

def request(
    notes: str = "", start: str = "", shape: str = "any", km: float = 3.0
) -> RunRequest {
    return RunRequest(
        level="intermediate",
        distance_km=km,
        area="downtown",
        time_of_day="morning",
        notes=notes,
        start=start,
        shape=shape
    );
}

def river_prefs(text: str) -> Preferences {
    return Preferences(wants=["river", "park"], avoids=["busy"], avoid_hills=True);
}

def no_prefs(text: str) -> Preferences {
    assert False , "parser must not be called without notes";
    return Preferences();
}

test "start must be a known landmark and shape one of the choices" {
    assert validate_request(request(start="Main Street")).accepted;
    assert not validate_request(request(start="Mars")).accepted;
    assert validate_request(request(shape="one-way")).accepted;
    assert not validate_request(request(shape="triangle")).accepted;
}

test "empty notes never call the parser" {
    prefs = preferences_for(request(""), no_prefs);
    assert prefs.wants == [] and prefs.shape == "any";
}

test "parsed preferences are limited to known tags and shapes" {
    def odd(text: str) -> Preferences {
        return Preferences(
            wants=["river", "unicorns"], avoids=["river", "busy"], shape="spiral"
        );
    }
    prefs = preferences_for(request("anything"), odd);
    assert prefs.wants == ["river"];
    assert prefs.avoids == ["busy"];
    assert prefs.shape == "any";
}

test "a failing parser falls back to no preferences" {
    def broken(text: str) -> Preferences {
        raise ValueError("model down");
    }
    assert preferences_for(request("see the river"), broken).wants == [];
}

test "the preference parser can be the mocked LLM" {
    mock = MockLLM(outputs=[Preferences(wants=["river"], shape="loop")]);
    def parse(text: str) -> Preferences by mock();
    prefs = preferences_for(request("I want to run by the river in a loop"), parse);
    assert prefs.wants == ["river"];
    assert prefs.shape == "loop";
    assert "river" in mock.seen_prompts[0];
}

test "bonus counts wanted and avoided tags per landmark" {
    bonus = preference_bonus(landmarks_for("downtown"), river_prefs(""));
    assert bonus["Argo Park"] >= 2.0;
    assert bonus["Main Street"] <= -1.0;
}

test "river notes put a river landmark on the route" {
    mock = MockLLM(outputs=[pick_first()]);
    def plan(
        req: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RoutePick by mock();
    route = generate_route(
        request("along the river please", start="Main Street"), plan, 1, river_prefs
    );
    assert route is not None;
    names = [w.name for w in route.waypoints];
    assert names[0] == "Main Street";
    river = [
        n
        for n in names
        if n
            in [
                "Argo Park",
                "Bandemer Park",
                "Argo Cascades",
                "Ann Arbor Train Station"
            ]
    ];
    assert len(river) > 0 , f"no river stop in {names}";
}

def pick_first -> RoutePick {
    return RoutePick(
        option=0,
        title="Morning run",
        stops=[],
        difficulty=2,
        difficulty_reason="Flat and short",
        safety_notes=["Watch the crossings"]
    );
}

test "the pool reaches further into neighbouring areas for long runs" {
    short = landmarks_for_request(request(km=1.0));
    long = landmarks_for_request(request(km=9.0));
    assert all([lm.area == "downtown" for lm in landmarks_for("downtown")]);
    assert len(long) > len(short);
    assert len(set([lm.area for lm in long])) == 3;
    assert len(
        [
            lm
            for lm in short
            if lm.area != "downtown"
        ]
    )
        < len(
            [
                lm
                for lm in long
                if lm.area != "downtown"
            ]
        );
}

test "the chosen start is always in the pool" {
    req = request(start="Nichols Arboretum");
    req.level = "beginner";
    req.area = "north-campus";
    assert "Nichols Arboretum" in [lm.name for lm in landmarks_for_request(req)];
}

test "a title that names a place off the route fails the check" {
    route = example_route();
    route.title = "Sprint to Nichols Arboretum";
    errors = check_route(route, landmarks_for("central-campus"));
    assert len(errors) == 1 and "title" in errors[0];
}

test "route carries shape and climb from the measured option" {
    mock = MockLLM(outputs=[pick_first()]);
    def plan(
        req: RunRequest, landmarks: list[Landmark], options: list[RouteOption]
    ) -> RoutePick by mock();
    route = generate_route(request(shape="out-and-back"), plan, 1, river_prefs);
    assert route is not None;
    assert route.shape == "out-and-back";
    assert route.climb_m >= 0;
}
