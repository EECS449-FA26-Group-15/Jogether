import from routes { RunRequest, validate_request }

def sample(distance: float = 2.0) -> RunRequest {
    return RunRequest(
        level="beginner",
        distance_km=distance,
        area="central-campus",
        time_of_day="morning"
    );
}

test "accepts the beginner happy path" {
    result = validate_request(sample());
    assert result.accepted;
    assert result.errors == [];
    assert result.request.distance_km == 2.0;
}

test "accepts distance boundaries" {
    assert validate_request(sample(0.5)).accepted;
    assert validate_request(sample(10.0)).accepted;
}

test "rejects zero negative and out of range distances" {
    for distance in [0.0, -1.0, 0.49, 10.01] {
        assert not validate_request(sample(distance)).accepted;
    }
}

test "rejects non finite distances" {
    for distance in [float("nan"), float("inf"), float("-inf")] {
        assert not validate_request(sample(distance)).accepted;
    }
}

test "accepts all supported levels areas and times" {
    for level in ["beginner", "intermediate", "experienced"] {
        for area in ["central-campus", "north-campus", "downtown"] {
            for time in ["morning", "afternoon", "evening"] {
                assert validate_request(
                    RunRequest(
                        level=level, distance_km=2.0, area=area, time_of_day=time
                    )
                ).accepted;
            }
        }
    }
}

test "rejects an unknown level" {
    request = sample();
    request.level = "expert";
    result = validate_request(request);
    assert not result.accepted;
    assert len(result.errors) == 1;
    assert "level" in result.errors[0];
}

test "rejects an unknown area" {
    request = sample();
    request.area = "anywhere";
    result = validate_request(request);
    assert not result.accepted;
    assert "area" in result.errors[0];
}

test "rejects an unknown time" {
    request = sample();
    request.time_of_day = "midnight";
    result = validate_request(request);
    assert not result.accepted;
    assert "time_of_day" in result.errors[0];
}

test "reports all invalid answers at once" {
    result = validate_request(
        RunRequest(level="", distance_km=0.0, area="", time_of_day="")
    );
    assert not result.accepted;
    assert len(result.errors) == 4;
}

