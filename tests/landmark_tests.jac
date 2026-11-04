import json;
import tempfile;
import from pathlib { Path }
import from landmark_data { load_landmarks }
import from unittest.mock { patch }
import from jaclang.byllm.lib { MockLLM }
import route_agent;
import from route_agent { generate_route }
import from routes { RunRequest }

def fixture -> dict[str, str] {
    return {
        "name": "TEST A",
        "description": "Fictional",
        "lighting": "unknown",
        "surface": "paved",
        "good_time_of_day": "morning"
    };
}

test "loads typed landmarks from a supplied JSON file" {
    with tempfile.TemporaryDirectory() as directory {
        path = Path(directory) / "landmarks.json";
        path.write_text(json.dumps({"central-campus": [fixture()]}), encoding="utf-8");
        data = load_landmarks(str(path));
        assert data["central-campus"][0].name == "TEST A";
        assert data["central-campus"][0].lighting == "unknown";
    }
}

test "rejects malformed landmark shapes and fields" {
    with tempfile.TemporaryDirectory() as directory {
        path = Path(directory) / "landmarks.json";
        for text in [
            "not JSON",
            "[]",
            "{\"elsewhere\": []}",
            "{\"central-campus\": {}}",
            "{\"central-campus\": [42]}",
            "{\"central-campus\": [{}]}"
        ] {
            path.write_text(text, encoding="utf-8");
            with testraises(ValueError) {
                load_landmarks(str(path));
            }
        }
        for field in [
            "name",
            "description",
            "lighting",
            "surface",
            "good_time_of_day"
        ] {
            record = fixture();
            record[field] = " ";
            path.write_text(json.dumps({"central-campus": [record]}), encoding="utf-8");
            with testraises(ValueError) {
                load_landmarks(str(path));
            }
        }
    }
}

test "duplicate landmark names fail before model invocation" {
    with tempfile.TemporaryDirectory() as directory {
        path = Path(directory) / "landmarks.json";
        path.write_text(
            json.dumps({"central-campus": [fixture(), fixture()]}), encoding="utf-8"
        );
        data = load_landmarks(str(path));
        mock = MockLLM(outputs=[]);
        with patch.object(route_agent, "llm", mock) {
            with testraises(ValueError, `match="unique") {
                generate_route(
                    RunRequest(
                        level="beginner",
                        distance_km=2.0,
                        area="central-campus",
                        time_of_day="morning"
                    ),
                    data
                );
            }
        }
        assert len(mock.seen) == 0;
    }
}
