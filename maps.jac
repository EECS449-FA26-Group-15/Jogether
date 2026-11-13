"""Route geometry for the page's map: the walking path and the numbered stops.

The page draws these with Leaflet over OpenStreetMap tiles. The line follows
the OSRM foot router (routing.openstreetmap.de) when it answers, and falls
back to straight lines between stops.
"""

import json;
import urllib.request;
import from geo_data { COORDS }
import from routes { RouteResult }

glob OSRM_URL: str = "https://routing.openstreetmap.de/routed-foot/route/v1/foot/",
     USER_AGENT: str = "Jogether-course-project/0.3 (EECS 449, UMich)";

"""A numbered stop on the map."""
obj MapStop {
    has lat: float,
        lon: float,
        label: str,
        name: str;
}

"""What the page draws for one route: the line as (lat, lon) points, and the stops.

`followed_streets` says whether the line came from the router or is straight.
"""
obj RouteGeometry {
    has line: list[tuple[float, float]],
        stops: list[MapStop],
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

"""The geometry of a planned route: its walking path and its stops numbered in order."""
def route_geometry(route: RouteResult, fetcher: Fetcher = fetch_url) -> RouteGeometry {
    (line, followed) = walking_path(route_points(route), fetcher);
    stops = [
        MapStop(
            lat=COORDS[w.name][0], lon=COORDS[w.name][1], label=str(i + 1), name=w.name
        )
        for (i, w) in enumerate(route.waypoints)
        if w.name in COORDS
    ];
    return RouteGeometry(line=line, stops=stops, followed_streets=followed);
}
