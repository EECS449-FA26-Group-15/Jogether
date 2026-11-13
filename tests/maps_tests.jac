import json;
import from geo_data { COORDS }
import from maps { route_geometry, route_points, walking_path }
import from routes { example_route }

def no_network(url: str) -> str {
    raise OSError("offline in tests");
}

def osrm_reply(url: str) -> str {
    assert url.startswith(
        "https://routing.openstreetmap.de/routed-foot/route/v1/foot/"
    );
    assert "geometries=geojson" in url;
    return json.dumps(
        {
            "routes": [
                {
                    "geometry": {
                        "coordinates": [
                            [-83.74151, 42.27517],
                            [-83.7400, 42.2760],
                            [-83.73801, 42.2771]
                        ]
                    }
                }
            ]
        }
    );
}

test "a loop returns to its first stop and an out-and-back comes back" {
    route = example_route();
    loop = route_points(route);
    assert len(loop) == len(route.waypoints) + 1;
    assert loop[0] == loop[-1];
    route.shape = "out-and-back";
    back = route_points(route);
    assert len(back) == 2 * len(route.waypoints) - 1;
    assert back[0] == back[-1];
    assert back[len(route.waypoints) - 1] == COORDS[route.waypoints[-1].name];
    route.shape = "one-way";
    assert len(route_points(route)) == len(route.waypoints);
}

test "the walking path comes from the router and is cached" {
    diag = COORDS["The Diag"];
    union = COORDS["Michigan Union"];
    (path, followed) = walking_path([union, diag], osrm_reply);
    assert followed;
    assert len(path) == 3;
    assert abs(path[0][0] - 42.27517) < 1e-6 and abs(path[0][1] + 83.74151) < 1e-6;
    (again, cached) = walking_path([union, diag], no_network);
    assert cached and again == path;
}

test "without the router the path is the straight line between stops" {
    tower = COORDS["Burton Memorial Tower"];
    arb = COORDS["Nichols Arboretum"];
    (path, followed) = walking_path([tower, arb], no_network);
    assert not followed;
    assert path == [tower, arb];
}

test "the route geometry numbers the stops in running order" {
    geometry = route_geometry(example_route(), no_network);
    assert [s.label for s in geometry.stops] == ["1", "2", "3", "4"];
    assert geometry.stops[0].name == "Michigan Union";
    assert (geometry.stops[0].lat, geometry.stops[0].lon) == COORDS["Michigan Union"];
    assert not geometry.followed_streets;
    assert len(geometry.line) == 5;
    assert geometry.line[0] == geometry.line[-1];
}
