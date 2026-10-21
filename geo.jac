"""Landmark coordinates and route distances, so the code (not the LLM) measures routes.

Coordinates come from OpenStreetMap Nominatim (October 2026). Streets use one
representative point: Main Street at 220 S Main, Law Quadrangle at Hutchins Hall.
Leg distances are real walking distances from the OSRM foot router (WALK_KM);
a pair missing from that table falls back to straight-line distance times 1.3.
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

"""Walking distances in km between landmark pairs in the same area, from the OSRM foot
router on OpenStreetMap (routing.openstreetmap.de, October 2026). Key: "A|B"."""
glob WALK_KM: dict[str, float] = {
         "The Diag|Michigan Union": 0.391,
         "The Diag|Ingalls Mall": 0.28,
         "The Diag|Burton Memorial Tower": 0.296,
         "The Diag|Law Quadrangle": 0.525,
         "The Diag|Observatory Street": 0.842,
         "The Diag|Palmer Field": 0.845,
         "The Diag|Nichols Arboretum": 1.746,
         "Michigan Union|Ingalls Mall": 0.642,
         "Michigan Union|Burton Memorial Tower": 0.607,
         "Michigan Union|Law Quadrangle": 0.211,
         "Michigan Union|Observatory Street": 1.233,
         "Michigan Union|Palmer Field": 1.236,
         "Michigan Union|Nichols Arboretum": 2.001,
         "Ingalls Mall|Burton Memorial Tower": 0.049,
         "Ingalls Mall|Law Quadrangle": 0.775,
         "Ingalls Mall|Observatory Street": 0.832,
         "Ingalls Mall|Palmer Field": 0.64,
         "Ingalls Mall|Nichols Arboretum": 1.808,
         "Burton Memorial Tower|Law Quadrangle": 0.742,
         "Burton Memorial Tower|Observatory Street": 0.865,
         "Burton Memorial Tower|Palmer Field": 0.689,
         "Burton Memorial Tower|Nichols Arboretum": 1.841,
         "Law Quadrangle|Observatory Street": 1.367,
         "Law Quadrangle|Palmer Field": 1.337,
         "Law Quadrangle|Nichols Arboretum": 2.028,
         "Observatory Street|Palmer Field": 0.399,
         "Observatory Street|Nichols Arboretum": 1.205,
         "Palmer Field|Nichols Arboretum": 1.617,
         "Pierpont Commons|Duderstadt Center": 0.301,
         "Pierpont Commons|Lurie Tower": 0.234,
         "Pierpont Commons|Wave Field": 0.77,
         "Pierpont Commons|Bonisteel Boulevard": 0.325,
         "Pierpont Commons|North Campus Recreation Building": 0.566,
         "Pierpont Commons|Gerald R. Ford Presidential Library": 0.77,
         "Pierpont Commons|Fuller Park": 1.447,
         "Duderstadt Center|Lurie Tower": 0.444,
         "Duderstadt Center|Wave Field": 0.715,
         "Duderstadt Center|Bonisteel Boulevard": 0.152,
         "Duderstadt Center|North Campus Recreation Building": 0.799,
         "Duderstadt Center|Gerald R. Ford Presidential Library": 0.585,
         "Duderstadt Center|Fuller Park": 1.557,
         "Lurie Tower|Wave Field": 0.609,
         "Lurie Tower|Bonisteel Boulevard": 0.354,
         "Lurie Tower|North Campus Recreation Building": 0.577,
         "Lurie Tower|Gerald R. Ford Presidential Library": 0.672,
         "Lurie Tower|Fuller Park": 1.665,
         "Wave Field|Bonisteel Boulevard": 0.625,
         "Wave Field|North Campus Recreation Building": 0.931,
         "Wave Field|Gerald R. Ford Presidential Library": 0.69,
         "Wave Field|Fuller Park": 2.155,
         "Bonisteel Boulevard|North Campus Recreation Building": 0.823,
         "Bonisteel Boulevard|Gerald R. Ford Presidential Library": 0.463,
         "Bonisteel Boulevard|Fuller Park": 1.531,
         "North Campus Recreation Building|Gerald R. Ford Presidential Library": 1.23,
         "North Campus Recreation Building|Fuller Park": 1.409,
         "Gerald R. Ford Presidential Library|Fuller Park": 1.613,
         "Main Street|Kerrytown": 0.651,
         "Main Street|Ann Arbor Farmers Market": 0.587,
         "Main Street|Liberty Plaza": 0.433,
         "Main Street|Ann Arbor District Library": 0.464,
         "Main Street|Wheeler Park": 1.09,
         "Main Street|Argo Park": 1.582,
         "Main Street|West Park": 0.984,
         "Kerrytown|Ann Arbor Farmers Market": 0.226,
         "Kerrytown|Liberty Plaza": 0.715,
         "Kerrytown|Ann Arbor District Library": 0.748,
         "Kerrytown|Wheeler Park": 0.583,
         "Kerrytown|Argo Park": 0.941,
         "Kerrytown|West Park": 1.026,
         "Ann Arbor Farmers Market|Liberty Plaza": 0.777,
         "Ann Arbor Farmers Market|Ann Arbor District Library": 0.81,
         "Ann Arbor Farmers Market|Wheeler Park": 0.61,
         "Ann Arbor Farmers Market|Argo Park": 1.102,
         "Ann Arbor Farmers Market|West Park": 0.958,
         "Liberty Plaza|Ann Arbor District Library": 0.33,
         "Liberty Plaza|Wheeler Park": 1.212,
         "Liberty Plaza|Argo Park": 1.444,
         "Liberty Plaza|West Park": 1.415,
         "Ann Arbor District Library|Wheeler Park": 1.329,
         "Ann Arbor District Library|Argo Park": 1.667,
         "Ann Arbor District Library|West Park": 1.446,
         "Wheeler Park|Argo Park": 0.861,
         "Wheeler Park|West Park": 1.447,
         "Argo Park|West Park": 1.939
     };

"""Paths are longer than straight lines; 1.3 is a common walking detour factor."""
glob DETOUR: float = 1.3,
     LAP_PENALTY: float = 0.1,
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

"""Walking distance between two landmarks in km: measured when we have it, else estimated."""
def leg_km(a: str, b: str) -> float {
    if a == b {
        return 0.0;
    }
    for key in [f"{a}|{b}", f"{b}|{a}"] {
        if key in WALK_KM {
            return WALK_KM[key];
        }
    }
    return straight_km(a, b) * DETOUR;
}

"""Straight-line (great-circle) distance between two landmarks, in km."""
def straight_km(a: str, b: str) -> float {
    (lat1, lon1) = COORDS[a];
    (lat2, lon2) = COORDS[b];
    p1 = math.radians(lat1);
    p2 = math.radians(lat2);
    dp = p2 - p1;
    dl = math.radians(lon2 - lon1);
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2;
    return 2 * 6371.0 * math.asin(math.sqrt(h));
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
        # One big loop wins if it is within ~10% of the target; otherwise an
        # extra lap (2 x a medium loop) is better than coming up short.
        return abs(option.distance_km - target_km) / target_km
            + LAP_PENALTY * (option.laps - 1);
    }
    candidates.sort(key=miss);
    best_miss = miss(candidates[0]);
    close = [
        c
        for c in candidates
        if miss(c) <= best_miss + 0.05
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
