"""Landmark seed list: names, areas, draft lighting/surface/times, and tags.

Coordinates and walking distances are NOT here; tools/build_geo.py looks them up
(Nominatim, OSRM, Open-Meteo) and writes geo_data.jac. Existing coordinates from
the first prototype are kept in KNOWN_COORDS so they do not drift between builds.

Lighting and surface are still draft values: check them on the ground.
"""

ALL_DAY = ["morning", "afternoon", "evening"]
DAYTIME = ["morning", "afternoon"]

# name, area, description, lighting, surface, good_times, tags, nominatim query
LANDMARKS = [
    # ---- central campus ----
    ("The Diag", "central-campus", "Open square where central campus paths meet", "lit", "pavement", ALL_DAY, ["campus", "busy", "flat"], None),
    ("Michigan Union", "central-campus", "Student union at State and South University", "lit", "pavement", ALL_DAY, ["campus", "busy", "historic"], None),
    ("Ingalls Mall", "central-campus", "Lawn and walkway between Hill Auditorium and Rackham", "lit", "pavement", ALL_DAY, ["campus", "park", "flat"], None),
    ("Burton Memorial Tower", "central-campus", "Carillon tower beside Ingalls Mall", "lit", "pavement", ALL_DAY, ["campus", "historic"], None),
    ("Law Quadrangle", "central-campus", "Gothic courtyard south of the Union", "lit", "pavement", ALL_DAY, ["campus", "historic", "quiet"], None),
    ("Observatory Street", "central-campus", "Street along the east edge of campus, with a steady hill", "lit", "pavement", ALL_DAY, ["campus", "hill"], None),
    ("Palmer Field", "central-campus", "Running track and fields behind the Hill dorms", "partly lit", "track", DAYTIME, ["campus", "track", "flat"], None),
    ("Nichols Arboretum", "central-campus", "Wooded valley trails down to the Huron River", "unlit", "dirt trail", DAYTIME, ["nature", "trail", "river", "hill", "quiet"], None),
    ("Michigan Stadium", "central-campus", "The Big House, with wide sidewalks around it", "lit", "pavement", ALL_DAY, ["stadium", "flat", "busy"], "Michigan Stadium, Ann Arbor"),
    ("Elbel Field", "central-campus", "Open practice field south of campus", "partly lit", "grass", DAYTIME, ["campus", "flat", "quiet"], "Elbel Field, Ann Arbor"),
    ("Hill Auditorium", "central-campus", "Concert hall at the north end of Ingalls Mall", "lit", "pavement", ALL_DAY, ["campus", "historic"], "Hill Auditorium, Ann Arbor"),
    ("Michigan League", "central-campus", "Student center on North University", "lit", "pavement", ALL_DAY, ["campus", "historic"], "Michigan League, Ann Arbor"),
    ("Central Campus Recreation Building", "central-campus", "Campus gym on Washtenaw Avenue", "lit", "pavement", ALL_DAY, ["campus"], "401 Washtenaw Avenue, Ann Arbor"),
    ("East Quadrangle", "central-campus", "Residence hall on East University", "lit", "pavement", ALL_DAY, ["campus", "quiet"], "East Quadrangle, Ann Arbor"),
    ("Island Park", "central-campus", "Small riverside park with a footbridge over the Huron", "partly lit", "pavement", DAYTIME, ["river", "park", "nature", "flat", "quiet"], "Island Park, Ann Arbor"),
    ("Gallup Park", "central-campus", "Long riverside park with paved paths and bridges", "partly lit", "pavement", DAYTIME, ["river", "park", "nature", "flat", "trail"], "Gallup Park, Ann Arbor"),
    # ---- north campus ----
    ("Pierpont Commons", "north-campus", "North campus student center", "lit", "pavement", ALL_DAY, ["campus", "busy"], None),
    ("Duderstadt Center", "north-campus", "Library and media center beside the engineering buildings", "lit", "pavement", ALL_DAY, ["campus"], None),
    ("Lurie Tower", "north-campus", "Bell tower at the centre of north campus", "lit", "pavement", ALL_DAY, ["campus", "historic"], None),
    ("Wave Field", "north-campus", "Grass earthwork sculpture beside the aerospace building", "partly lit", "grass", DAYTIME, ["campus", "quiet", "park"], None),
    ("Bonisteel Boulevard", "north-campus", "Main north campus road with wide sidewalks", "lit", "pavement", ALL_DAY, ["campus", "flat"], None),
    ("North Campus Recreation Building", "north-campus", "Campus gym on Hubbard Road", "lit", "pavement", ALL_DAY, ["campus"], None),
    ("Gerald R. Ford Presidential Library", "north-campus", "Presidential library on Beal Avenue", "lit", "pavement", ALL_DAY, ["campus", "historic", "quiet"], None),
    ("Fuller Park", "north-campus", "Riverside park with pool and fields below north campus", "partly lit", "pavement", DAYTIME, ["river", "park", "flat"], None),
    ("Bursley Hall", "north-campus", "Large residence hall on the north side of campus", "lit", "pavement", ALL_DAY, ["campus"], "Bursley Hall, Ann Arbor"),
    ("Mitchell Field", "north-campus", "Playing fields along Fuller Road by the river", "partly lit", "grass", DAYTIME, ["park", "river", "flat", "quiet"], "Mitchell Field, Ann Arbor"),
    ("Walgreen Drama Center", "north-campus", "Theatre building on the north campus arts corridor", "lit", "pavement", ALL_DAY, ["campus"], "Walgreen Drama Center, Ann Arbor"),
    ("Earl V. Moore Building", "north-campus", "School of Music building beside a small lake", "lit", "pavement", ALL_DAY, ["campus", "quiet", "nature"], "Earl V. Moore Building, Ann Arbor"),
    ("Ford Robotics Building", "north-campus", "Robotics building at the east edge of north campus", "lit", "pavement", ALL_DAY, ["campus", "quiet"], "Ford Robotics Building, Ann Arbor"),
    ("Baits Houses", "north-campus", "Residence halls on the wooded north edge", "lit", "pavement", ALL_DAY, ["campus", "quiet", "hill"], "Baits II, Ann Arbor"),
    # ---- downtown ----
    ("Main Street", "downtown", "Downtown restaurant strip", "lit", "pavement", ALL_DAY, ["shops", "busy", "flat"], None),
    ("Kerrytown", "downtown", "Market district north of downtown", "lit", "pavement", ALL_DAY, ["shops", "historic"], None),
    ("Ann Arbor Farmers Market", "downtown", "Open-air market shed in Kerrytown", "lit", "pavement", DAYTIME, ["shops", "busy"], None),
    ("Liberty Plaza", "downtown", "Small square at Liberty and Division", "lit", "pavement", DAYTIME, ["shops", "busy"], None),
    ("Ann Arbor District Library", "downtown", "Downtown library on Fifth Avenue", "lit", "pavement", ALL_DAY, ["shops", "flat"], None),
    ("Wheeler Park", "downtown", "Neighbourhood park north of Kerrytown", "partly lit", "grass", DAYTIME, ["park", "quiet", "flat"], None),
    ("Argo Park", "downtown", "Riverside park at the Argo dam and canoe livery", "partly lit", "gravel path", DAYTIME, ["river", "park", "nature", "trail"], None),
    ("West Park", "downtown", "Hilly park with a band shell west of downtown", "partly lit", "pavement", DAYTIME, ["park", "hill", "quiet"], None),
    ("Bandemer Park", "downtown", "Riverside park across the Huron from Argo", "unlit", "gravel path", DAYTIME, ["river", "park", "nature", "trail", "quiet"], "Bandemer Park, Ann Arbor"),
    ("Argo Cascades", "downtown", "Chain of small rapids beside the Argo canoe livery", "partly lit", "pavement", DAYTIME, ["river", "nature", "park"], "Argo Cascades, Ann Arbor"),
    ("Michigan Theater", "downtown", "Historic cinema on Liberty Street", "lit", "pavement", ALL_DAY, ["shops", "historic", "busy"], "Michigan Theater, Ann Arbor"),
    ("Allmendinger Park", "downtown", "Flat neighbourhood park southwest of downtown", "partly lit", "grass", DAYTIME, ["park", "quiet", "flat"], "Allmendinger Park, Ann Arbor"),
    ("Burns Park", "downtown", "Large park with a loop path in the Burns Park neighbourhood", "partly lit", "pavement", DAYTIME, ["park", "quiet", "flat"], "Burns Park, Ann Arbor"),
    ("Veterans Memorial Park", "downtown", "Park with a loop path and ice arena on Dexter Avenue", "partly lit", "pavement", DAYTIME, ["park", "flat"], "Veterans Memorial Park, Ann Arbor"),
    ("Nickels Arcade", "downtown", "Covered shopping arcade off State Street", "lit", "pavement", ALL_DAY, ["shops", "historic"], "Nickels Arcade, Ann Arbor"),
    ("Ann Arbor Train Station", "downtown", "Amtrak station on Depot Street by the river", "lit", "pavement", ALL_DAY, ["historic", "river", "flat"], "Ann Arbor Amtrak Station, Depot Street, Ann Arbor"),
]

# Coordinates already used by the prototype (OSM Nominatim, October 2026). Kept fixed.
KNOWN_COORDS = {
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
    "West Park": (42.28362, -83.75594),
}
