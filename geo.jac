"""Landmark coordinates and route distances, so the code (not the LLM) measures routes.

Coordinates come from OpenStreetMap Nominatim (October 2026). Streets use one
representative point: Main Street at 220 S Main, Law Quadrangle at Hutchins Hall.
Distances are straight-line legs times a detour factor, so they are estimates.
"""

import itertools;
import math;
import random;

glob COORDS: dict[str, tuple[float, float]] = {
         "The Diag": (42.27710, -83.73801),
         "Michigan Union": (42.27517, -83.74151),
         "Ingalls Mall": (42.27946, -83.73821),
         "Burton Memorial Tower": (42.27942, -83.73871),
         "Law Quadrangle": (42.27367, -83.74036),
         "Observatory Street": (42.28069, -83.73108),
         "Palmer Field": (42.28066, -83.73271),
         "Nichols Arboretum": (42.27908, -83.72238),
         "Pierpont Commons": (42.29112, -83.71760),
         "Duderstadt Center": (42.29118, -83.71577),
         "Lurie Tower": (42.29203, -83.71618),
         "Wave Field": (42.29318, -83.71164),
         "Bonisteel Boulevard": (42.29025, -83.71569),
         "North Campus Recreation Building": (42.29554, -83.72017),
         "Gerald R. Ford Presidential Library": (42.28857, -83.71229),
         "Fuller Park": (42.28879, -83.72822),
         "Main Street": (42.27984, -83.74877),
         "Kerrytown": (42.28421, -83.74588),
         "Ann Arbor Farmers Market": (42.28394, -83.74661),
         "Liberty Plaza": (42.27920, -83.74439),
         "Ann Arbor District Library": (42.27817, -83.74571),
         "Wheeler Park": (42.28783, -83.74540),
         "Argo Park": (42.28995, -83.74141),
         "West Park": (42.28362, -83.75594)
     };

"""Paths are longer than straight lines; 1.3 is a common walking detour factor."""
glob DETOUR: float = 1.3,
     MAX_LAPS: int = 4,
     MIN_STOPS: int = 3,
     MAX_STOPS: int = 6;

"""One candidate loop: visit the stops in order, return to the first, repeat laps times."""
obj RouteOption {
    has stops: list[str],
        laps: int,
        loop_km: float,
        distance_km: float;
}

"""Walking estimate between two landmarks, in km."""
def leg_km(a: str, b: str) -> float {
    (lat1, lon1) = COORDS[a];
    (lat2, lon2) = COORDS[b];
    p1 = math.radians(lat1);
    p2 = math.radians(lat2);
    dp = p2 - p1;
    dl = math.radians(lon2 - lon1);
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2;
    return 2 * 6371.0 * math.asin(math.sqrt(h)) * DETOUR;
}

"""Length of one loop through the stops and back to the first stop, in km."""
def loop_km(stops: list[str]) -> float {
    total = 0.0;
    for i in range(len(stops)) {
        total += leg_km(stops[i], stops[(i + 1) % len(stops)]);
    }
    return total;
}

"""The shortest loop order for a set of stops, keeping the first stop fixed."""
def best_order(stops: list[str]) -> list[str] {
    first = stops[0];
    best: list[str] = stops;
    best_len = loop_km(stops);
    for rest in itertools.permutations(stops[1:]) {
        order = [first] + list(rest);
        length = loop_km(order);
        if length < best_len {
            best = order;
            best_len = length;
        }
    }
    return best;
}

"""Loops built from these landmarks whose total length is close to the target.

Each set of 3 to 6 stops becomes its shortest loop; laps are added when the
area is too small for the target. The closest candidates are shuffled, then up
to `count` options with different stop sets are returned.
"""
def route_options(
    names: list[str], target_km: float, count: int = 3, seed: int | None = None
) -> list[RouteOption] {
    known = [
        n
        for n in names
        if n in COORDS
    ];
    if len(known) < MIN_STOPS or not math.isfinite(target_km) or target_km <= 0 {
        return [];
    }
    candidates: list[RouteOption] = [];
    for size in range(MIN_STOPS, min(MAX_STOPS, len(known)) + 1) {
        for combo in itertools.combinations(known, size) {
            stops = best_order(list(combo));
            one_loop = loop_km(stops);
            laps = max(1, min(MAX_LAPS, round(target_km / one_loop)));
            candidates.append(
                RouteOption(
                    stops=stops,
                    laps=laps,
                    loop_km=round(one_loop, 2),
                    distance_km=round(one_loop * laps, 1)
                )
            );
        }
    }
    def miss(option: RouteOption) -> float {
        return abs(option.distance_km - target_km) / target_km
            + 0.05 * (option.laps - 1);
    }
    candidates.sort(key=miss);
    best_miss = miss(candidates[0]);
    close = [
        c
        for c in candidates
        if miss(c) <= best_miss + 0.1
    ][:40];
    rng = random.Random(seed);
    rng.shuffle(close);
    picked: list[RouteOption] = [];
    for option in close + candidates {
        if all(set(option.stops) != set(p.stops) for p in picked) {
            picked.append(option);
        }
        if len(picked) == count {
            break;
        }
    }
    return picked;
}
