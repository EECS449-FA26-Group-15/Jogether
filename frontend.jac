"""Jogether demo page: your answers in, three AI-planned routes on a map out."""

import from maps { MapView }
import from planner { PlannedRoute, RunPlan, plan_run, sample_run }
import from routes { RouteResult }

glob GREEN: str = "#1f6f4a",
     INK: str = "#14342b",
     MUTED: str = "#5b6b60",
     TINT: str = "#eef4ef",
     LINE: str = "#d5e0d8",
     RED: str = "#a3382a";

def:pub app -> JsxElement {
    has level: str = "beginner",
        distance: str = "2",
        unit: str = "mi",
        area: str = "central-campus",
        time_of_day: str = "morning",
        notes: str = "",
        address: str = "",
        shape: str = "any",
        loading: bool = False,
        plan: RunPlan | None = None,
        chosen: int = -1,
        connection_error: str = "";

    async def generate {
        loading = True;
        plan = None;
        chosen = -1;
        connection_error = "";
        try {
            plan = await plan_run(
                level, distance, unit, area, time_of_day, notes, address, shape
            );
            if plan is not None and len(plan.routes) == 1 {
                chosen = 0;
            }
        } except Exception {
            connection_error = "Could not reach the planner. Check your connection and try again.";
        } finally {
            loading = False;
        }
    }

    async def show_example {
        connection_error = "";
        try {
            plan = await sample_run(unit);
            chosen = 0;
        } except Exception {
            connection_error = "Could not load the example. Please try again.";
        }
    }

    label_style = {
        "display": "block",
        "fontSize": "13px",
        "fontWeight": "600",
        "color": MUTED,
        "marginBottom": "6px"
    };
    field_style = {
        "width": "100%",
        "padding": "10px 12px",
        "border": f"1px solid {LINE}",
        "borderRadius": "10px",
        "fontSize": "15px",
        "background": "white",
        "boxSizing": "border-box"
    };
    card_style = {
        "background": "white",
        "borderRadius": "16px",
        "padding": "20px",
        "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
    };

    <div
        style={{
            "minHeight": "100vh",
            "background": "#f6faf7",
            "fontFamily": "system-ui, -apple-system, Segoe UI, sans-serif",
            "color": INK,
            "padding": "32px 16px"
        }}
    >
        <div style={{"maxWidth": "960px", "margin": "0 auto"}}>
            <div style={{"maxWidth": "640px", "margin": "0 auto"}}>
                <h1 style={{"margin": "0", "fontSize": "40px", "color": INK}}>
                    Jogether
                </h1>
                <p
                    style={{
                        "margin": "4px 0 24px",
                        "color": GREEN,
                        "fontStyle": "italic"
                    }}
                >
                    Run together, from your first mile.
                </p>
                <div style={card_style}>
                    <div
                        style={{
                            "display": "grid",
                            "gridTemplateColumns": "1fr 1fr",
                            "gap": "14px"
                        }}
                    >
                        <div>
                            <label style={label_style}>Your level</label>
                            <select
                                style={field_style}
                                value={level}
                                onChange={lambda (e: ChangeEvent) { level = e.target.value; }}
                            >
                                <option value="beginner">Beginner</option>
                                <option value="intermediate">Intermediate</option>
                                <option value="experienced">Experienced</option>
                            </select>
                        </div>
                        <div>
                            <label style={label_style}>Distance</label>
                            <div style={{"display": "flex", "gap": "8px"}}>
                                <input
                                    style={{** field_style, "flex": "1"}}
                                    type="number"
                                    min="0.3"
                                    step="0.5"
                                    value={distance}
                                    onChange={lambda (e: ChangeEvent) { distance = e.target.value; }}
                                />
                                <select
                                    style={{** field_style, "width": "84px"}}
                                    value={unit}
                                    onChange={lambda (e: ChangeEvent) { unit = e.target.value; }}
                                >
                                    <option value="mi">miles</option>
                                    <option value="km">km</option>
                                </select>
                            </div>
                        </div>
                        <div>
                            <label style={label_style}>Area</label>
                            <select
                                style={field_style}
                                value={area}
                                onChange={lambda (e: ChangeEvent) { area = e.target.value; }}
                            >
                                <option value="central-campus">Central Campus</option>
                                <option value="north-campus">North Campus</option>
                                <option value="downtown">Downtown</option>
                            </select>
                        </div>
                        <div>
                            <label style={label_style}>Time of day</label>
                            <select
                                style={field_style}
                                value={time_of_day}
                                onChange={lambda (e: ChangeEvent) { time_of_day = e.target.value; }}
                            >
                                <option value="morning">Morning</option>
                                <option value="afternoon">Afternoon</option>
                                <option value="evening">Evening</option>
                            </select>
                        </div>
                        <div>
                            <label style={label_style}>Route shape</label>
                            <select
                                style={field_style}
                                value={shape}
                                onChange={lambda (e: ChangeEvent) { shape = e.target.value; }}
                            >
                                <option value="any">Any</option>
                                <option value="loop">Loop (end where you start)</option>
                                <option value="out-and-back">Out and back</option>
                                <option value="one-way">One way</option>
                            </select>
                        </div>
                        <div>
                            <label style={label_style}>Start address (optional)</label>
                            <input
                                style={field_style}
                                type="text"
                                placeholder="e.g. 500 S State St"
                                value={address}
                                onChange={lambda (e: ChangeEvent) { address = e.target.value; }}
                            />
                        </div>
                    </div>
                    <p
                        style={{
                            "margin": "8px 0 0",
                            "fontSize": "12px",
                            "color": MUTED
                        }}
                    >
                        With an address, the routes start right there. Leave it blank to start anywhere in the area.
                    </p>
                    <div style={{"marginTop": "14px"}}>
                        <label style={label_style}>Anything else? (optional)</label>
                        <textarea
                            style={{
                                ** field_style,
                                "minHeight": "60px",
                                "resize": "vertical"
                            }}
                            placeholder="e.g. I'd like to see the river, and not too many hills"
                            value={notes}
                            onChange={lambda (e: ChangeEvent) { notes = e.target.value; }}
                        />
                    </div>
                    <button
                        onClick={generate}
                        disabled={loading}
                        style={{
                            "marginTop": "16px",
                            "width": "100%",
                            "padding": "14px",
                            "border": "none",
                            "borderRadius": "12px",
                            "background": "#9bb5a6" if loading else GREEN,
                            "color": "white",
                            "fontSize": "16px",
                            "fontWeight": "700",
                            "cursor": "wait" if loading else "pointer"
                        }}
                    >
                        {"Planning three routes... (10 to 30 seconds)"
                            if loading
                            else "Show me three routes"}
                    </button>
                </div>
                {if connection_error {
                    <p role="alert" style={{"color": RED}}>{connection_error}</p>
                }}
            </div>
            {if plan is not None and len(plan.routes) == 0 {
                <div style={{"maxWidth": "640px", "margin": "20px auto 0"}}>
                    <Problems plan={plan} on_example={show_example}/>
                </div>
            }}
            {if plan is not None and len(plan.routes) > 0 {
                <div style={{"marginTop": "28px"}}>
                    <h2 style={{"margin": "0 0 4px"}}>
                        {"Your example route"
                            if plan.is_example
                            else (
                                "Pick your route"
                                    if len(plan.routes) > 1
                                    else "Your route"
                            )}
                    </h2>
                    <p style={{"margin": "0 0 16px", "color": MUTED}}>
                        {plan.start_note
                            if plan.start_note
                            else (
                                "Hand-written, not AI-generated."
                                    if plan.is_example
                                    else f"{len(plan.routes)} routes planned in {plan.seconds:.1f}s, best fit first. Tap one to see every stop."
                            )}
                    </p>
                    <div
                        style={{
                            "display": "grid",
                            "gridTemplateColumns": "repeat(auto-fit, minmax(280px, 1fr))",
                            "gap": "16px"
                        }}
                    >
                        {for (i, pr) in enumerate(plan.routes) {
                            <div
                                key={str(i)}
                                style={{
                                    ** card_style,
                                    "padding": "12px",
                                    "border": f"2px solid {GREEN}"
                                        if chosen == i
                                        else "2px solid transparent"
                                }}
                            >
                                <RouteMap view={pr.view}/>
                                <h3
                                    style={{"margin": "12px 0 8px", "fontSize": "18px"}}
                                >
                                    {f"{i + 1}. {pr.route.title}"}
                                </h3>
                                <RoutePills route={pr.route} unit={plan.unit}/>
                                <p
                                    style={{
                                        "margin": "10px 0 12px",
                                        "color": MUTED,
                                        "fontSize": "14px"
                                    }}
                                >
                                    {pr.route.difficulty_reason}
                                </p>
                                <button
                                    onClick={lambda (e: any) { chosen = i; }}
                                    style={{
                                        "width": "100%",
                                        "padding": "10px",
                                        "border": f"1px solid {GREEN}",
                                        "borderRadius": "10px",
                                        "background": GREEN if chosen == i else "white",
                                        "color": "white" if chosen == i else GREEN,
                                        "fontWeight": "700",
                                        "cursor": "pointer"
                                    }}
                                >
                                    {"Chosen" if chosen == i else "Choose this route"}
                                </button>
                            </div>
                        }}
                    </div>
                    {if 0 <= chosen and chosen < len(plan.routes) {
                        <RouteDetail planned={plan.routes[chosen]} plan={plan}/>
                    }}
                </div>
            }}
            <p
                style={{
                    "marginTop": "24px",
                    "fontSize": "12px",
                    "color": MUTED,
                    "textAlign": "center"
                }}
            >
                Routes are planned by an open-weight model (gemma3:4b) running locally, using only our curated landmark list. Map tiles © OpenStreetMap contributors. Always check your surroundings.
            </p>
        </div>
    </div>
}

"""Why there is no route: validation problems, or the planner gave nothing."""
def:pub Problems(plan: RunPlan, on_example: any) -> JsxElement {
    return
        <div
            style={{
                "background": "white",
                "borderRadius": "16px",
                "padding": "20px",
                "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
            }}
        >
            <h3 style={{"marginTop": "0", "color": RED}}>
                {"Please check your answers"
                    if not plan.accepted
                    else "No route this time"}
            </h3>
            <ul style={{"margin": "0 0 12px", "paddingLeft": "20px"}}>
                {for (i, err) in enumerate(plan.errors) {
                    <li key={str(i)}>{err}</li>
                }}
            </ul>
            {if plan.accepted {
                <button
                    onClick={on_example}
                    style={{
                        "padding": "10px 14px",
                        "border": f"1px solid {LINE}",
                        "borderRadius": "10px",
                        "background": TINT,
                        "cursor": "pointer"
                    }}
                >
                    Show an example route instead
                </button>
            }}
        </div>;
}

"""The route drawn over OpenStreetMap tiles, with its stops numbered."""
def:pub RouteMap(view: MapView) -> JsxElement {
    return
        <div
            style={{
                "position": "relative",
                "borderRadius": "12px",
                "overflow": "hidden",
                "border": f"1px solid {LINE}",
                "background": TINT
            }}
        >
            <svg
                viewBox={f"0 0 {view.width} {view.height}"}
                style={{"display": "block", "width": "100%", "height": "auto"}}
                role="img"
                aria-label="Map of the route"
            >
                {for (i, t) in enumerate(view.tiles) {
                    <image
                        key={str(i)}
                        href={t.url}
                        x={t.x}
                        y={t.y}
                        width="256"
                        height="256"
                    />
                }}
                <polyline
                    points={view.path}
                    fill="none"
                    stroke="white"
                    strokeWidth="9"
                    strokeLinejoin="round"
                    strokeLinecap="round"
                    opacity="0.9"
                />
                <polyline
                    points={view.path}
                    fill="none"
                    stroke={GREEN}
                    strokeWidth="5"
                    strokeLinejoin="round"
                    strokeLinecap="round"
                />
                {for (i, m) in enumerate(view.markers) {
                    <g key={str(i)}>
                        <circle
                            cx={m.x}
                            cy={m.y}
                            r="13"
                            fill={GREEN if i == 0 else "white"}
                            stroke={GREEN}
                            strokeWidth="3"
                        />
                        <text
                            x={m.x}
                            y={m.y + 5}
                            textAnchor="middle"
                            fontSize="14"
                            fontWeight="700"
                            fill={"white" if i == 0 else INK}
                        >
                            {m.label}
                        </text>
                    </g>
                }}
            </svg>
            <div
                style={{
                    "position": "absolute",
                    "right": "4px",
                    "bottom": "2px",
                    "fontSize": "10px",
                    "color": INK,
                    "background": "rgba(255,255,255,0.8)",
                    "padding": "1px 4px",
                    "borderRadius": "4px"
                }}
            >
                {view.attribution
                    if view.followed_streets
                    else f"{view.attribution} · straight lines between stops"}
            </div>
        </div>;
}

"""Distance, difficulty, climb and shape of a route as small labels."""
def:pub RoutePills(route: RouteResult, unit: str) -> JsxElement {
    dots = "●" * route.difficulty + "○" * (5 - route.difficulty);
    laps = route.laps if route.laps > 0 else 1;
    per_unit = 1.0 / 1.609344 if unit == "mi" else 1.0;
    unit_name = "mi" if unit == "mi" else "km";
    total = route.distance_km * per_unit;
    one_pass = total / laps;
    in_km = f" ({route.distance_km:.1f} km)" if unit == "mi" else "";
    shape_words = {
        "loop": "loop",
        "out-and-back": "out and back",
        "one-way": "one way"
    };
    shape_word = shape_words.get(route.shape, "loop");
    distance_label = (
        f"≈ {total:.1f} {unit_name}{in_km} · {laps} laps of {one_pass:.1f} {unit_name} {shape_word}"
            if laps > 1
            else f"≈ {total:.1f} {unit_name}{in_km} {shape_word}"
    );
    climb_label = f"{round(route.climb_m)} m uphill" if route.climb_m > 0 else "flat";
    pill_style = {
        "background": TINT,
        "padding": "6px 10px",
        "borderRadius": "999px",
        "fontWeight": "600",
        "fontSize": "14px"
    };
    return
        <div style={{"display": "flex", "gap": "8px", "flexWrap": "wrap"}}>
            <span style={pill_style}>{distance_label}</span>
            <span style={{** pill_style, "color": GREEN}}>
                {f"Difficulty {dots} {route.difficulty}/5"}
            </span>
            <span style={pill_style}>{climb_label}</span>
        </div>;
}

"""The chosen route in full: map, every stop, safety notes and the Google Maps link."""
def:pub RouteDetail(planned: PlannedRoute, plan: RunPlan) -> JsxElement {
    route = planned.route;
    return
        <div
            style={{
                "marginTop": "20px",
                "background": "white",
                "borderRadius": "16px",
                "padding": "20px",
                "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
            }}
        >
            {if plan.is_example {
                <div
                    style={{
                        "display": "inline-block",
                        "fontSize": "12px",
                        "fontWeight": "700",
                        "background": "#fbe8c2",
                        "padding": "4px 10px",
                        "borderRadius": "999px",
                        "marginBottom": "8px"
                    }}
                >
                    EXAMPLE ROUTE (hand-written, not AI-generated)
                </div>
            }}
            <h2 style={{"margin": "0 0 8px"}}>{route.title}</h2>
            <RoutePills route={route} unit={plan.unit}/>
            <p style={{"margin": "12px 0 14px", "color": MUTED}}>
                {route.difficulty_reason}
            </p>
            <div
                style={{
                    "display": "grid",
                    "gridTemplateColumns": "repeat(auto-fit, minmax(300px, 1fr))",
                    "gap": "18px"
                }}
            >
                <RouteMap view={planned.view}/>
                <div>
                    <ol style={{"margin": "0 0 14px", "paddingLeft": "22px"}}>
                        {for (i, w) in enumerate(route.waypoints) {
                            <li key={str(i)} style={{"marginBottom": "8px"}}>
                                <strong>{w.name}</strong>
                                {w.note
                                    and <div
                                        style={{"color": MUTED, "fontSize": "14px"}}
                                    >
                                        {w.note}
                                    </div>}
                            </li>
                        }}
                    </ol>
                    {if len(route.safety_notes) > 0 {
                        <div
                            style={{
                                "background": "#fff6e5",
                                "borderRadius": "12px",
                                "padding": "10px 14px",
                                "marginBottom": "14px"
                            }}
                        >
                            <strong>Safety notes</strong>
                            <ul style={{"margin": "6px 0 0", "paddingLeft": "20px"}}>
                                {for (i, n) in enumerate(route.safety_notes) {
                                    <li key={str(i)}>{n}</li>
                                }}
                            </ul>
                        </div>
                    }}
                    {if planned.maps_url {
                        <a
                            href={planned.maps_url}
                            target="_blank"
                            rel="noreferrer"
                            style={{"color": GREEN, "fontWeight": "700"}}
                        >
                            {"Open one pass in Google Maps"
                                if route.laps > 1
                                else "Open this route in Google Maps"}
                        </a>
                    }}
                    {if planned.maps_url and route.laps > 1 {
                        <p
                            style={{
                                "margin": "6px 0 0",
                                "fontSize": "13px",
                                "color": MUTED
                            }}
                        >
                            {f"Google Maps shows one pass. Run it {route.laps} times for the full distance."}
                        </p>
                    }}
                </div>
            </div>
        </div>;
}
