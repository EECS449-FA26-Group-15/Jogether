import json;
import from geo_data { COORDS }
import from maps {
    MAP_HEIGHT,
    MAP_WIDTH,
    fit_zoom,
    map_view,
    route_map,
    route_points,
    walking_path,
    world_px
}
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

test "web mercator puts north and east where they belong" {
    (x1, y1) = world_px(42.2771, -83.73801, 15);
    (x2, y2) = world_px(42.2900, -83.72000, 15);
    assert x2 > x1;
    assert y2 < y1;
}

test "the picture fits every stop inside its padding at the deepest zoom" {
    stops = [
        (
            COORDS["Michigan Stadium"][0],
            COORDS["Michigan Stadium"][1],
            "1",
            "Michigan Stadium"
        ),
        (COORDS["Gallup Park"][0], COORDS["Gallup Park"][1], "2", "Gallup Park")
    ];
    path = [(s[0], s[1]) for s in stops];
    view = map_view(path, stops);
    assert view.width == MAP_WIDTH and view.height == MAP_HEIGHT;
    assert fit_zoom(path, MAP_WIDTH, MAP_HEIGHT) == view.zoom;
    assert len(view.markers) == 2;
    for marker in view.markers {
        assert 0 <= marker.x <= view.width , f"x {marker.x}";
        assert 0 <= marker.y <= view.height , f"y {marker.y}";
    }
    assert len(view.tiles) > 0;
    for tile in view.tiles {
        assert tile.url.startswith(f"https://tile.openstreetmap.org/{view.zoom}/");
        assert -256 < tile.x < view.width and -256 < tile.y < view.height;
    }
    assert len(view.path.split(" ")) == 2;
    assert view.attribution != "";
}

test "a short route zooms in further than a long one" {
    near = [COORDS["The Diag"], COORDS["Michigan Union"]];
    far = [COORDS["Michigan Stadium"], COORDS["Gallup Park"]];
    assert fit_zoom(near, MAP_WIDTH, MAP_HEIGHT) > fit_zoom(far, MAP_WIDTH, MAP_HEIGHT);
}

test "the route map numbers the stops in running order" {
    view = route_map(example_route(), no_network);
    assert [m.label for m in view.markers] == ["1", "2", "3", "4"];
    assert view.markers[0].name == "Michigan Union";
    assert not view.followed_streets;
    assert len(view.path.split(" ")) == 5;
}
