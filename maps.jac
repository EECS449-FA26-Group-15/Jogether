"""Map pictures for the page: OpenStreetMap tiles with the route drawn on top.

Everything is computed on the server, so the page only draws what it is given:
which tiles to show, where the route line goes, and where the numbered stops
sit. The line follows the OSRM foot router (routing.openstreetmap.de) when it
answers, and falls back to straight lines between stops.
"""

import json;
import math;
import urllib.request;
import from geo_data { COORDS }
import from routes { RouteResult }

glob TILE_SIZE: int = 256,
     MAP_WIDTH: int = 640,
     MAP_HEIGHT: int = 400,
     MAP_PADDING: int = 36,
     MIN_ZOOM: int = 12,
     MAX_ZOOM: int = 17,
     OSRM_URL: str = "https://routing.openstreetmap.de/routed-foot/route/v1/foot/",
     ATTRIBUTION: str = "© OpenStreetMap contributors",
     USER_AGENT: str = "Jogether-course-project/0.3 (EECS 449, UMich)";

"""One 256 px map tile and where it sits inside the picture."""
obj MapTile {
    has url: str,
        x: int,
        y: int;
}

"""A numbered stop on the picture."""
obj MapMarker {
    has x: float,
        y: float,
        label: str,
        name: str;
}

"""What the page draws: tiles, the route as SVG polyline points, and markers.

`followed_streets` says whether the line came from the router or is straight.
"""
obj MapView {
    has width: int,
        height: int,
        zoom: int,
        tiles: list[MapTile],
        path: str,
        markers: list[MapMarker],
        attribution: str,
        followed_streets: bool = False;
}

glob Fetcher = Callable[[str], str];

"""Walking paths already fetched this session, by their stop coordinates."""
glob PATH_CACHE: dict[str, list[tuple[float, float]]] = {};

"""Coordinates of one pass of the route, in running order.

A loop returns to its first stop; an out-and-back comes back the same way.
"""
def route_points(route: RouteResult) -> list[tuple[float, float]] {
    stops = [
        COORDS[w.name]
        for w in route.waypoints
        if w.name in COORDS
    ];
    if len(stops) == 0 {
        return [];
    }
    if route.shape == "loop" {
        return stops + [stops[0]];
    }
    if route.shape == "out-and-back" {
        return stops + stops[::-1][1:];
    }
    return stops;
}

"""Fetch a URL as text with a short timeout and our User-Agent."""
def fetch_url(url: str) -> str {
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT});
    with urllib.request.urlopen(req, timeout=5) as resp {
        body = resp.read().decode("utf-8");
    }
    return body;
}

"""The walking path through the points from the OSRM foot router.

Returns the path and True, or the points themselves and False when the router
cannot be reached or gives no route.
"""
def walking_path(
    points: list[tuple[float, float]], fetcher: Fetcher = fetch_url
) -> tuple[list[tuple[float, float]], bool] {
    if len(points) < 2 {
        return (points, False);
    }
    key = ";".join([f"{p[0]:.5f},{p[1]:.5f}" for p in points]);
    if key in PATH_CACHE {
        return (PATH_CACHE[key], True);
    }
    coords = ";".join([f"{p[1]},{p[0]}" for p in points]);
    url = OSRM_URL + coords + "?overview=full&geometries=geojson&steps=false";
    try {
        data = json.loads(fetcher(url));
        line = data["routes"][0]["geometry"]["coordinates"];
        path = [(float(p[1]), float(p[0])) for p in line];
    } except Exception {
        return (points, False);
    }
    if len(path) < 2 {
        return (points, False);
    }
    PATH_CACHE[key] = path;
    return (path, True);
}

"""Web Mercator pixel position of a coordinate at this zoom (whole-world pixels)."""
def world_px(lat: float, lon: float, zoom: int) -> tuple[float, float] {
    scale = TILE_SIZE * (2 ** zoom);
    x = (lon + 180.0) / 360.0 * scale;
    rad = math.radians(max(-85.0, min(85.0, lat)));
    y = (1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0 * scale;
    return (x, y);
}

"""The largest zoom at which every point fits inside the picture with padding."""
def fit_zoom(points: list[tuple[float, float]], width: int, height: int) -> int {
    for zoom in range(MAX_ZOOM, MIN_ZOOM - 1, -1) {
        pixels = [world_px(p[0], p[1], zoom) for p in points];
        xs = [p[0] for p in pixels];
        ys = [p[1] for p in pixels];
        if max(xs) - min(xs) <= width - 2 * MAP_PADDING
            and max(ys) - min(ys) <= height - 2 * MAP_PADDING {
            return zoom;
        }
    }
    return MIN_ZOOM;
}

"""A picture of a path and its stops: tiles, polyline points, numbered markers.

`stops` are (lat, lon, label, name). The picture is centred on everything it
shows and zoomed as far in as the padding allows.
"""
def map_view(
    path: list[tuple[float, float]],
    stops: list[tuple[float, float, str, str]],
    followed_streets: bool = False,
    width: int = MAP_WIDTH,
    height: int = MAP_HEIGHT
) -> MapView {
    everything = path + [(s[0], s[1]) for s in stops];
    if len(everything) == 0 {
        return MapView(
            width=width,
            height=height,
            zoom=MIN_ZOOM,
            tiles=[],
            path="",
            markers=[],
            attribution=ATTRIBUTION
        );
    }
    zoom = fit_zoom(everything, width, height);
    pixels = [world_px(p[0], p[1], zoom) for p in everything];
    xs = [p[0] for p in pixels];
    ys = [p[1] for p in pixels];
    left = (min(xs) + max(xs)) / 2.0 - width / 2.0;
    top = (min(ys) + max(ys)) / 2.0 - height / 2.0;
    tiles: list[MapTile] = [];
    count = 2 ** zoom;
    first_x = int(math.floor(left / TILE_SIZE));
    last_x = int(math.floor((left + width) / TILE_SIZE));
    first_y = int(math.floor(top / TILE_SIZE));
    last_y = int(math.floor((top + height) / TILE_SIZE));
    for tx in range(first_x, last_x + 1) {
        for ty in range(first_y, last_y + 1) {
            if ty < 0 or ty >= count {
                continue;
            }
            tiles.append(
                MapTile(
                    url=f"https://tile.openstreetmap.org/{zoom}/{tx % count}/{ty}.png",
                    x=int(round(tx * TILE_SIZE - left)),
                    y=int(round(ty * TILE_SIZE - top))
                )
            );
        }
    }
    line = [world_px(p[0], p[1], zoom) for p in path];
    points = " ".join([f"{p[0] - left:.1f},{p[1] - top:.1f}" for p in line]);
    markers: list[MapMarker] = [];
    for s in stops {
        (px, py) = world_px(s[0], s[1], zoom);
        markers.append(
            MapMarker(
                x=round(px - left, 1), y=round(py - top, 1), label=s[2], name=s[3]
            )
        );
    }
    return MapView(
        width=width,
        height=height,
        zoom=zoom,
        tiles=tiles,
        path=points,
        markers=markers,
        attribution=ATTRIBUTION,
        followed_streets=followed_streets
    );
}

"""The map for a planned route: its walking path with the stops numbered in order."""
def route_map(route: RouteResult, fetcher: Fetcher = fetch_url) -> MapView {
    (path, followed) = walking_path(route_points(route), fetcher);
    stops = [
        (COORDS[w.name][0], COORDS[w.name][1], str(i + 1), w.name)
        for (i, w) in enumerate(route.waypoints)
        if w.name in COORDS
    ];
    return map_view(path, stops, followed);
}
