"""Curated landmarks the route agent may use, grouped by area.

Draft list: lighting and surface are best guesses. Check them on the ground
before the agent's safety notes rely on them.
"""

obj Landmark {
    has name: str;
    has description: str;
    has lighting: str;
    has surface: str;
    has good_times: list[str];
}

glob ALL_DAY: list[str] = ["morning", "afternoon", "evening"];
glob DAYTIME: list[str] = ["morning", "afternoon"];

def landmarks_for(area: str) -> list[Landmark] {
    areas: dict[str, list[Landmark]] = {
        "central-campus": [
            Landmark(
                name="The Diag",
                description="Open square where central campus paths meet",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Michigan Union",
                description="Student union at State and South University",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Ingalls Mall",
                description="Lawn and walkway between Hill Auditorium and Rackham",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Burton Memorial Tower",
                description="Carillon tower on North University Avenue",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Law Quadrangle",
                description="Gothic law school quad at State and South University",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Observatory Street",
                description="Steady climb past the Hill dorms, good for hill practice",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Palmer Field",
                description="Outdoor track and open fields near the Hill dorms",
                lighting="partly lit",
                surface="track",
                good_times=DAYTIME
            ),
            Landmark(
                name="Nichols Arboretum",
                description="Hilly trails and meadows down to the Huron River",
                lighting="unlit",
                surface="dirt trail",
                good_times=DAYTIME
            )
        ],
        "north-campus": [
            Landmark(
                name="Pierpont Commons",
                description="North Campus student center on Murfin Avenue",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Duderstadt Center",
                description="Library and media center beside the engineering buildings",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Lurie Tower",
                description="Bell tower at the center of the engineering campus",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Wave Field",
                description="Grassy wave-shaped earthwork by Maya Lin",
                lighting="partly lit",
                surface="grass",
                good_times=DAYTIME
            ),
            Landmark(
                name="Bonisteel Boulevard",
                description="Main North Campus road with wide sidewalks",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="North Campus Recreation Building",
                description="Campus gym on Hubbard Road",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Gerald R. Ford Presidential Library",
                description="Presidential library on Beal Avenue",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Fuller Park",
                description="City park on Fuller Road with a path toward the river",
                lighting="partly lit",
                surface="pavement",
                good_times=DAYTIME
            )
        ],
        "downtown": [
            Landmark(
                name="Main Street",
                description="Busy restaurant strip between William and Huron",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Kerrytown",
                description="Market district around Fourth Avenue and Detroit Street",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Ann Arbor Farmers Market",
                description="Open-air market in Kerrytown, crowded on market mornings",
                lighting="lit",
                surface="pavement",
                good_times=DAYTIME
            ),
            Landmark(
                name="Liberty Plaza",
                description="Small public plaza at Liberty and Division",
                lighting="lit",
                surface="pavement",
                good_times=DAYTIME
            ),
            Landmark(
                name="Ann Arbor District Library",
                description="Downtown library on Fifth Avenue",
                lighting="lit",
                surface="pavement",
                good_times=ALL_DAY
            ),
            Landmark(
                name="Wheeler Park",
                description="Small park near Kerrytown on Depot Street",
                lighting="partly lit",
                surface="grass",
                good_times=DAYTIME
            ),
            Landmark(
                name="Argo Park",
                description="Riverside park with the Argo Cascades and a river path",
                lighting="partly lit",
                surface="gravel path",
                good_times=DAYTIME
            ),
            Landmark(
                name="West Park",
                description="Park west of downtown with a bandshell and paths",
                lighting="partly lit",
                surface="pavement",
                good_times=DAYTIME
            )
        ]
    };
    return areas.get(area, []);
}
