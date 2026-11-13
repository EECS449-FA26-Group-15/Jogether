"""Jogether page: the questions on the left, a live map on the right.

The map can be panned and zoomed from the start. Double-click it to pin where
the run starts, or type an address. After planning, three short route blocks
appear under the form; the chosen one is drawn on the map.
"""

import "leaflet/dist/leaflet.css";
import from "leaflet" {
    divIcon,
    latLngBounds,
    layerGroup,
    map as leafletMap,
    marker,
    polyline,
    tileLayer
}
import from "react" { useEffect }
import from planner { PlannedRoute, RunPlan, plan_run, sample_run }
import from routes { RouteResult }

glob GREEN: str = "#1f6f4a",
     LIGHT_GREEN: str = "#a9cbb8",
     INK: str = "#14342b",
     MUTED: str = "#5b6b60",
     TINT: str = "#eef4ef",
     LINE: str = "#d5e0d8",
     RED: str = "#a3382a",
     ANN_ARBOR_LAT: float = 42.278,
     ANN_ARBOR_LON: float = -83.738,
     START_ZOOM: int = 14;

glob APP_CSS: str = """
body { margin: 0; }
.jog-root { display: grid; grid-template-columns: minmax(380px, 1fr) 2fr; min-height: 100vh; background: #f6faf7; color: #14342b; font-family: system-ui, -apple-system, Segoe UI, sans-serif; }
.jog-side { padding: 24px 20px 40px; box-sizing: border-box; max-height: 100vh; overflow-y: auto; }
.jog-map-wrap { position: sticky; top: 0; height: 100vh; }
.jog-map { height: 100%; width: 100%; background: #e8eee9; }
.jog-hint { position: absolute; top: 12px; left: 56px; z-index: 1001; pointer-events: none; background: rgba(255,255,255,0.92); color: #14342b; font-size: 13px; font-weight: 600; padding: 6px 10px; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,0.15); }
.jog-stop { width: 26px; height: 26px; border-radius: 50%; border: 3px solid #1f6f4a; box-sizing: border-box; display: flex; align-items: center; justify-content: center; font: 700 13px system-ui, sans-serif; }
.jog-pin { width: 20px; height: 20px; border-radius: 50%; background: #c0392b; border: 3px solid white; box-sizing: border-box; box-shadow: 0 1px 4px rgba(0,0,0,0.45); }
@media (max-width: 900px) {
  .jog-root { grid-template-columns: 1fr; }
  .jog-side { max-height: none; overflow: visible; }
  .jog-map-wrap { position: static; height: 60vh; }
}
""";

"""A promise that resolves after `ms` milliseconds, for short pauses in handlers."""
def pause(ms: int) -> any {
    return new(
        Promise,
        lambda (resolve: any, reject: any) { setTimeout(
            lambda { resolve.call(None, True); }, ms
        ); }
    );
}

"""A numbered stop marker; the first stop is filled green."""
def stop_icon(label: str, first: bool) -> any {
    bg = GREEN if first else "white";
    fg = "white" if first else INK;
    html = "<div class=\"jog-stop\" style=\"background:"
        + bg
        + ";color:"
        + fg
        + "\">"
        + label
        + "</div>";
    return divIcon(
        {"html": html, "className": "", "iconSize": [26, 26], "iconAnchor": [13, 13]}
    );
}

"""The red dot that marks where the runner double-clicked."""
def pin_icon -> any {
    return divIcon(
        {
            "html": "<div class=\"jog-pin\"></div>",
            "className": "",
            "iconSize": [20, 20],
            "iconAnchor": [10, 10]
        }
    );
}

def:pub app -> JsxElement {
    has level: str = "beginner",
        distance: str = "2",
        unit: str = "mi",
        area: str = "central-campus",
        time_of_day: str = "morning",
        notes: str = "",
        address: str = "",
        shape: str = "any",
        has_pin: bool = False,
        pin_lat: float = 0.0,
        pin_lon: float = 0.0,
        loading: bool = False,
        progress: float = 0.0,
        plan: RunPlan | None = None,
        chosen: int = -1,
        connection_error: str = "";
    has mapRef: Ref[HTMLDivElement] = Ref();
    has leafletRef: Ref[any] = Ref(None);
    has routeLayerRef: Ref[any] = Ref(None);
    has pinLayerRef: Ref[any] = Ref(None);
    has timerRef: Ref[any] = Ref(None);

    def place_pin(lat: float, lon: float) {
        has_pin = True;
        pin_lat = lat;
        pin_lon = lon;
        address = "";
    }

    def clear_pin {
        has_pin = False;
    }

    def pin_text -> str {
        return f"{pin_lat},{pin_lon}" if has_pin else "";
    }

    def tick_progress {
        if progress < 78.0 {
            progress = 78.0 if progress + 3.0 > 78.0 else progress + 3.0;
        } else {
            progress = progress + (96.0 - progress) * 0.015;
        }
    }

    def start_progress {
        progress = 0.0;
        if timerRef.current {
            clearInterval(timerRef.current);
        }
        timerRef.current = setInterval(tick_progress, 100);
    }

    def stop_progress {
        if timerRef.current {
            clearInterval(timerRef.current);
            timerRef.current = None;
        }
    }

    async def generate {
        loading = True;
        plan = None;
        chosen = -1;
        connection_error = "";
        start_progress();
        try {
            plan = await plan_run(
                level,
                distance,
                unit,
                area,
                time_of_day,
                notes,
                address,
                shape,
                pin_text()
            );
            if plan is not None and len(plan.routes) == 1 {
                chosen = 0;
            }
        } except Exception {
            connection_error = "Could not reach the planner. Check your connection and try again.";
        } finally {
            stop_progress();
            progress = 100.0;
            await pause(350);
            loading = False;
            progress = 0.0;
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

    useEffect(
        lambda {
            container = mapRef.current;
            if not container {
                return lambda {};
            }
            m = leafletMap(container, {"doubleClickZoom": False});
            m.setView([ANN_ARBOR_LAT, ANN_ARBOR_LON], START_ZOOM);
            tileLayer(
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                {"maxZoom": 19, "attribution": "© OpenStreetMap contributors"}
            ).addTo(
                m
            );
            m.on(
                "dblclick", lambda (e: any) { place_pin(e.latlng.lat, e.latlng.lng); }
            );
            leafletRef.current = m;
            return lambda {
                m.remove();
                leafletRef.current = None;
            };
        },
        []
    );

    can with [has_pin, pin_lat, pin_lon] entry {
        m = leafletRef.current;
        if not m {
            return;
        }
        if pinLayerRef.current {
            m.removeLayer(pinLayerRef.current);
            pinLayerRef.current = None;
        }
        if has_pin {
            pinLayerRef.current = marker(
                [pin_lat, pin_lon], {"icon": pin_icon(), "title": "Your start"}
            ).addTo(
                m
            );
        }
    }

    can with [chosen, plan] entry {
        m = leafletRef.current;
        if not m {
            return;
        }
        if routeLayerRef.current {
            m.removeLayer(routeLayerRef.current);
            routeLayerRef.current = None;
        }
        if plan is None or chosen < 0 or chosen >= len(plan.routes) {
            return;
        }
        geometry = plan.routes[chosen].geometry;
        points = [[p[0], p[1]] for p in geometry.line];
        group = layerGroup();
        polyline(
            points, {"color": "white", "weight": 9, "opacity": 0.9, "lineJoin": "round"}
        ).addTo(
            group
        );
        polyline(points, {"color": GREEN, "weight": 5, "lineJoin": "round"}).addTo(
            group
        );
        for (i, s) in enumerate(geometry.stops) {
            marker(
                [s.lat, s.lon], {"icon": stop_icon(s.label, i == 0), "title": s.name}
            ).addTo(
                group
            );
        }
        group.addTo(m);
        routeLayerRef.current = group;
        if len(points) > 0 {
            m.fitBounds(latLngBounds(points), {"padding": [40, 40]});
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
        "padding": "18px",
        "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
    };

    <div className="jog-root">
        <style>{APP_CSS}</style>
        <div className="jog-side">
            <h1 style={{"margin": "0", "fontSize": "34px", "color": INK}}>Jogether</h1>
            <p style={{"margin": "4px 0 18px", "color": GREEN, "fontStyle": "italic"}}>
                Run together, from your first mile.
            </p>
            <div style={card_style}>
                <div
                    style={{
                        "display": "grid",
                        "gridTemplateColumns": "1fr 1fr",
                        "gap": "12px"
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
                                style={{** field_style, "flex": "1", "minWidth": "0"}}
                                type="number"
                                min="0.3"
                                step="0.5"
                                value={distance}
                                onChange={lambda (e: ChangeEvent) { distance = e.target.value; }}
                            />
                            <select
                                style={{** field_style, "width": "80px"}}
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
                            onChange={lambda (e: ChangeEvent) {
                                address = e.target.value;
                                has_pin = False;
                            }}
                        />
                    </div>
                </div>
                {if has_pin {
                    <p style={{"margin": "8px 0 0", "fontSize": "13px", "color": INK}}>
                        {f"Start pinned on the map at {pin_lat:.4f}, {pin_lon:.4f}."}{" "}
                        <button
                            onClick={clear_pin}
                            style={{
                                "border": "none",
                                "background": "none",
                                "color": GREEN,
                                "fontWeight": "700",
                                "cursor": "pointer",
                                "padding": "0"
                            }}
                        >
                            Clear
                        </button>
                    </p>
                } else {
                    <p
                        style={{
                            "margin": "8px 0 0",
                            "fontSize": "12px",
                            "color": MUTED
                        }}
                    >
                        Double-click the map to pin your start, or type an address. Leave both blank to start anywhere in the area.
                    </p>
                } }
                <div style={{"marginTop": "12px"}}>
                    <label style={label_style}>Anything else? (optional)</label>
                    <textarea
                        style={{
                            ** field_style,
                            "minHeight": "56px",
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
                        "marginTop": "14px",
                        "width": "100%",
                        "padding": "14px",
                        "border": "none",
                        "borderRadius": "12px",
                        "background": LIGHT_GREEN if loading else GREEN,
                        "color": "white",
                        "fontSize": "16px",
                        "fontWeight": "700",
                        "cursor": "wait" if loading else "pointer",
                        "position": "relative",
                        "overflow": "hidden"
                    }}
                >
                    {if loading {
                        <span
                            style={{
                                "position": "absolute",
                                "left": "0",
                                "top": "0",
                                "bottom": "0",
                                "width": f"{progress:.1f}%",
                                "background": GREEN,
                                "transition": "width 0.1s linear"
                            }}
                        />
                    }}
                    <span style={{"position": "relative"}}>
                        {"Planning three routes..."
                            if loading
                            else "Show me three routes"}
                    </span>
                </button>
            </div>
            {if connection_error {
                <p role="alert" style={{"color": RED}}>{connection_error}</p>
            }}
            {if plan is not None and len(plan.routes) == 0 {
                <div style={{"marginTop": "16px"}}>
                    <Problems plan={plan} on_example={show_example}/>
                </div>
            }}
            {if plan is not None and len(plan.routes) > 0 {
                <div style={{"marginTop": "20px"}}>
                    <h2 style={{"margin": "0 0 4px", "fontSize": "22px"}}>
                        {"Your example route"
                            if plan.is_example
                            else (
                                "Pick your route"
                                    if len(plan.routes) > 1
                                    else "Your route"
                            )}
                    </h2>
                    <p
                        style={{
                            "margin": "0 0 12px",
                            "color": MUTED,
                            "fontSize": "14px"
                        }}
                    >
                        {plan.start_note
                            if plan.start_note
                            else (
                                "Hand-written, not AI-generated."
                                    if plan.is_example
                                    else f"{len(plan.routes)} routes planned in {plan.seconds:.1f}s, best fit first. Tap one to see it on the map."
                            )}
                    </p>
                    {for (i, pr) in enumerate(plan.routes) {
                        <div
                            key={str(i)}
                            style={{
                                ** card_style,
                                "padding": "14px",
                                "marginBottom": "12px",
                                "border": f"2px solid {GREEN}"
                                    if chosen == i
                                    else "2px solid transparent"
                            }}
                        >
                            <h3 style={{"margin": "0 0 8px", "fontSize": "17px"}}>
                                {f"{i + 1}. {pr.route.title}"}
                            </h3>
                            <RoutePills route={pr.route} unit={plan.unit}/>
                            <p
                                style={{
                                    "margin": "10px 0 10px",
                                    "color": MUTED,
                                    "fontSize": "14px"
                                }}
                            >
                                {pr.route.difficulty_reason}
                            </p>
                            <button
                                onClick={lambda (e: MouseEvent) { chosen = i; }}
                                style={{
                                    "width": "100%",
                                    "padding": "9px",
                                    "border": f"1px solid {GREEN}",
                                    "borderRadius": "10px",
                                    "background": GREEN if chosen == i else "white",
                                    "color": "white" if chosen == i else GREEN,
                                    "fontWeight": "700",
                                    "cursor": "pointer"
                                }}
                            >
                                {"On the map" if chosen == i else "Show on the map"}
                            </button>
                            {if chosen == i {
                                <RouteDetails
                                    planned={pr}
                                    is_example={plan.is_example}
                                />
                            }}
                        </div>
                    }}
                </div>
            }}
            <p
                style={{
                    "marginTop": "20px",
                    "fontSize": "12px",
                    "color": MUTED,
                    "textAlign": "center"
                }}
            >
                Routes are planned by an open-weight model (gemma3:4b) running locally, using only our curated landmark list. Map © OpenStreetMap contributors. Always check your surroundings.
            </p>
        </div>
        <div className="jog-map-wrap">
            <div ref={mapRef} className="jog-map" role="application" aria-label="Map"/>
            <div className="jog-hint">Double-click the map to set your start</div>
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
                "padding": "18px",
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

"""Distance, difficulty and climb of a route as small labels."""
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
        "padding": "5px 9px",
        "borderRadius": "999px",
        "fontWeight": "600",
        "fontSize": "13px"
    };
    return
        <div style={{"display": "flex", "gap": "6px", "flexWrap": "wrap"}}>
            <span style={pill_style}>{distance_label}</span>
            <span style={{** pill_style, "color": GREEN}}>
                {f"Difficulty {dots} {route.difficulty}/5"}
            </span>
            <span style={pill_style}>{climb_label}</span>
        </div>;
}

"""The chosen route in full: every stop, safety notes and the Google Maps link."""
def:pub RouteDetails(planned: PlannedRoute, is_example: bool) -> JsxElement {
    route = planned.route;
    return
        <div
            style={{
                "marginTop": "12px",
                "borderTop": f"1px solid {LINE}",
                "paddingTop": "12px"
            }}
        >
            {if is_example {
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
            <ol style={{"margin": "0 0 12px", "paddingLeft": "22px"}}>
                {for (i, w) in enumerate(route.waypoints) {
                    <li key={str(i)} style={{"marginBottom": "6px"}}>
                        <strong>{w.name}</strong>
                        {w.note
                            and <div style={{"color": MUTED, "fontSize": "13px"}}>
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
                        "marginBottom": "12px"
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
            {if not planned.geometry.followed_streets {
                <p style={{"margin": "0 0 10px", "fontSize": "12px", "color": MUTED}}>
                    The router did not answer, so the line is drawn straight from stop to stop.
                </p>
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
                <p style={{"margin": "6px 0 0", "fontSize": "13px", "color": MUTED}}>
                    {f"Google Maps shows one pass. Run it {route.laps} times for the full distance."}
                </p>
            }}
        </div>;
}
