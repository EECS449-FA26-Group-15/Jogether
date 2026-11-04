"""JSON adapter for the provisional issue #4 landmark-file contract."""

import json;
import from route_contract { Landmark }

def text_field(record: dict[str, object], key: str) -> str {
    value = record.get(key);
    if not isinstance(value, str) or not value.strip() {
        raise ValueError(f"Landmark field {key} must be a nonempty string");
    }
    return str(value);
}

def load_landmarks(path: str) -> dict[str, list[Landmark]] {
    with open(path, encoding="utf-8") as source {
        data = json.load(source);
    }
    if not isinstance(data, dict) {
        raise ValueError("Landmark file must map area names to lists of landmarks");
    }
    areas: dict[str, list[Landmark]] = {};
    for (area, records) in data.items() {
        if area not in ["central-campus", "north-campus", "downtown"] {
            raise ValueError(f"Unknown landmark area: {area}");
        }
        if not isinstance(records, list) {
            raise ValueError(f"Landmarks for {area} must be a list");
        }
        landmarks: list[Landmark] = [];
        for record in records {
            if not isinstance(record, dict) {
                raise ValueError("Each landmark must be an object");
            }
            landmarks.append(
                Landmark(
                    name=text_field(record, "name"),
                    description=text_field(record, "description"),
                    lighting=text_field(record, "lighting"),
                    surface=text_field(record, "surface"),
                    good_time_of_day=text_field(record, "good_time_of_day")
                )
            );
        }
        areas[str(area)] = landmarks;
    }
    return areas;
}
