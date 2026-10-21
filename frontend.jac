"""Jogether demo page: four questions in, an AI-planned route out."""

import from planner { RunPlan, plan_run, sample_run }

glob GREEN: str = "#1f6f4a",
     INK: str = "#14342b",
     MUTED: str = "#5b6b60",
     TINT: str = "#eef4ef",
     LINE: str = "#d5e0d8";

def:pub app -> JsxElement {
    has level: str = "beginner",
        distance: str = "3",
        area: str = "central-campus",
        time_of_day: str = "morning",
        notes: str = "",
        loading: bool = False,
        plan: RunPlan | None = None;

    async def generate {
        loading = True;
        plan = None;
        plan = await plan_run(level, distance, area, time_of_day, notes);
        loading = False;
    }

    async def show_example {
        plan = await sample_run();
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

    <div
        style={{
            "minHeight": "100vh",
            "background": "#f6faf7",
            "fontFamily": "system-ui, -apple-system, Segoe UI, sans-serif",
            "color": INK,
            "padding": "32px 16px"
        }}
    >
        <div style={{"maxWidth": "640px", "margin": "0 auto"}}>
            <h1 style={{"margin": "0", "fontSize": "40px", "color": INK}}>Jogether</h1>
            <p style={{"margin": "4px 0 24px", "color": GREEN, "fontStyle": "italic"}}>
                Run together, from your first mile.
            </p>
            <div
                style={{
                    "background": "white",
                    "borderRadius": "16px",
                    "padding": "20px",
                    "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
                }}
            >
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
                        <label style={label_style}>Distance (km)</label>
                        <input
                            style={field_style}
                            type="number"
                            min="0.5"
                            max="10"
                            step="0.5"
                            value={distance}
                            onChange={lambda (e: ChangeEvent) { distance = e.target.value; }}
                        />
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
                </div>
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
                    {"Planning your run... (a few seconds)"
                        if loading
                        else "Generate my route"}
                </button>
            </div>
            {if plan is not None {
                <RouteCard plan={plan} on_example={show_example}/>
            }}
            <p
                style={{
                    "marginTop": "24px",
                    "fontSize": "12px",
                    "color": MUTED,
                    "textAlign": "center"
                }}
            >
                Routes are planned by an open-weight model (gemma3:4b) running locally, using only our curated landmark list. Always check your surroundings.
            </p>
        </div>
    </div>
}

def:pub RouteCard(plan: RunPlan, on_example: any) -> JsxElement {
    card_style = {
        "marginTop": "20px",
        "background": "white",
        "borderRadius": "16px",
        "padding": "20px",
        "boxShadow": "0 1px 4px rgba(0,0,0,0.08)"
    };
    route = plan.route;
    if route is None {
        return
            <div style={card_style}>
                <h3 style={{"marginTop": "0", "color": "#a3382a"}}>
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
    dots = "●" * route.difficulty + "○" * (5 - route.difficulty);
    return
        <div style={card_style}>
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
            <div
                style={{
                    "display": "flex",
                    "gap": "10px",
                    "flexWrap": "wrap",
                    "marginBottom": "12px"
                }}
            >
                <span
                    style={{
                        "background": TINT,
                        "padding": "6px 10px",
                        "borderRadius": "999px",
                        "fontWeight": "600"
                    }}
                >
                    {f"{route.distance_km:.1f} km"}
                </span>
                <span
                    style={{
                        "background": TINT,
                        "padding": "6px 10px",
                        "borderRadius": "999px",
                        "fontWeight": "600",
                        "color": GREEN
                    }}
                >
                    {f"Difficulty {dots} {route.difficulty}/5"}
                </span>
                {if not plan.is_example {
                    <span
                        style={{
                            "padding": "6px 4px",
                            "color": MUTED,
                            "fontSize": "13px"
                        }}
                    >
                        {f"planned in {plan.seconds:.1f}s"}
                    </span>
                }}
            </div>
            <p style={{"margin": "0 0 14px", "color": MUTED}}>
                {route.difficulty_reason}
            </p>
            <ol style={{"margin": "0 0 14px", "paddingLeft": "22px"}}>
                {for (i, w) in enumerate(route.waypoints) {
                    <li key={str(i)} style={{"marginBottom": "8px"}}>
                        <strong>{w.name}</strong>
                        {w.note
                            and <div style={{"color": MUTED, "fontSize": "14px"}}>
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
            {if plan.maps_url {
                <a
                    href={plan.maps_url}
                    target="_blank"
                    rel="noreferrer"
                    style={{"color": GREEN, "fontWeight": "700"}}
                >
                    Open this route in Google Maps
                </a>
            }}
        </div>;
}
