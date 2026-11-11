"""Responsive running planner and route results."""

import from planner { RunPlan, plan_run, sample_run }
import from ui_styles { APP_STYLES }

def:pub app -> JsxElement {
    has level: str = "beginner",
        distance: str = "2",
        unit: str = "mi",
        area: str = "central-campus",
        time_of_day: str = "morning",
        notes: str = "",
        loading: bool = False,
        loading_example: bool = False,
        plan: RunPlan | None = None,
        connection_error: str = "";

    async def generate {
        if loading or loading_example {
            return;
        }
        loading = True;
        plan = None;
        connection_error = "";
        try {
            plan = await plan_run(level, distance, unit, area, time_of_day, notes);
        } except Exception {
            connection_error = "Could not reach the planner. Check your connection and try again.";
        } finally {
            loading = False;
        }
    }

    async def show_example {
        if loading or loading_example {
            return;
        }
        loading_example = True;
        plan = None;
        connection_error = "";
        try {
            plan = await sample_run(unit);
        } except Exception {
            connection_error = "Could not load the example. Please try again.";
        } finally {
            loading_example = False;
        }
    }

    <div className="jogether">
        <style>{APP_STYLES}</style>
        <a className="skip-link" href="#planner">Skip to route planner</a>
        <header className="site-header shell">
            <a className="brand" href="#top" aria-label="Jogether home">
                <span className="brand-mark" aria-hidden="true">j.</span>
                jogether
                <span className="brand-dot">.</span>
            </a>
            <nav aria-label="Main navigation">
                <a href="#planner">Plan a run</a>
                <a href="#how-it-works">How it works</a>
            </nav>
            <span className="location">
                Ann Arbor, MI{" "}
                <span aria-hidden="true">↗</span>
            </span>
        </header>
        <main id="top" className="shell">
            <section className="intro" aria-labelledby="intro-title">
                <div>
                    <p className="eyebrow">A little movement. A little discovery.</p>
                    <h1 id="intro-title">
                        Your next mile,
                        <br/>
                        <em>your kind of run.</em>
                    </h1>
                </div>
                <p className="intro-copy">
                    A fresh route around Ann Arbor, shaped around you. Pick your pace, find your places, and head outside.
                </p>
            </section>
            <div id="planner" className="planner-grid">
                <section className="form-panel" aria-labelledby="form-title">
                    <div className="panel-heading">
                        <div>
                            <p className="eyebrow">01 / Make it yours</p>
                            <h2 id="form-title">What feels good today?</h2>
                        </div>
                        <span className="heading-icon" aria-hidden="true">↗</span>
                    </div>
                    <fieldset className="fields" disabled={loading or loading_example}>
                        <legend className="sr-only">Your running preferences</legend>
                        <div className="field">
                            <label htmlFor="run-level">Your level</label>
                            <select
                                id="run-level"
                                value={level}
                                onChange={lambda (e: ChangeEvent) { level = e.target.value; }}
                            >
                                <option value="beginner">Beginner</option>
                                <option value="intermediate">Intermediate</option>
                                <option value="experienced">Experienced</option>
                            </select>
                        </div>
                        <div className="field">
                            <label htmlFor="run-distance">Distance</label>
                            <div className="distance-input">
                                <input
                                    id="run-distance"
                                    type="number"
                                    step="any"
                                    value={distance}
                                    aria-describedby="distance-help"
                                    onChange={lambda (e: ChangeEvent) { distance = e.target.value; }}
                                />
                                <select
                                    id="run-unit"
                                    aria-label="Distance unit"
                                    value={unit}
                                    onChange={lambda (e: ChangeEvent) { unit = e.target.value; }}
                                >
                                    <option value="mi">miles</option>
                                    <option value="km">km</option>
                                </select>
                            </div>
                            <span id="distance-help" className="field-hint">
                                {"0.5–10 km"
                                    if unit == "km"
                                    else "About 0.31–6.21 miles (0.5–10 km)"}
                            </span>
                        </div>
                        <div className="field">
                            <label htmlFor="run-area">Your neighborhood</label>
                            <select
                                id="run-area"
                                value={area}
                                onChange={lambda (e: ChangeEvent) { area = e.target.value; }}
                            >
                                <option value="central-campus">Central Campus</option>
                                <option value="north-campus">North Campus</option>
                                <option value="downtown">Downtown</option>
                            </select>
                        </div>
                        <div className="field">
                            <label htmlFor="run-time">Time of day</label>
                            <select
                                id="run-time"
                                value={time_of_day}
                                onChange={lambda (e: ChangeEvent) { time_of_day = e.target.value; }}
                            >
                                <option value="morning">Morning</option>
                                <option value="afternoon">Afternoon</option>
                                <option value="evening">Evening</option>
                            </select>
                        </div>
                        <div className="field full-width">
                            <label htmlFor="run-notes">
                                A little more you{" "}
                                <span className="optional">optional</span>
                            </label>
                            <textarea
                                id="run-notes"
                                maxLength={300}
                                rows={3}
                                placeholder="By the river? Fewer hills? Tell us what you're in the mood for."
                                value={notes}
                                onChange={lambda (e: ChangeEvent) { notes = e.target.value; }}
                            />
                        </div>
                    </fieldset>
                    <button
                        className="primary-button"
                        onClick={generate}
                        disabled={loading or loading_example}
                    >
                        {"Planning your run…" if loading else "Find my route"}
                        <span aria-hidden="true">↗</span>
                    </button>
                    <button
                        className="example-button"
                        onClick={show_example}
                        disabled={loading or loading_example}
                    >
                        {"Loading example…"
                            if loading_example
                            else "Just exploring? Preview an example route"}
                    </button>
                </section>
                <section
                    className="result-panel"
                    aria-label="Your route"
                    aria-live="polite"
                    aria-busy={loading or loading_example}
                >
                    {if loading or loading_example {
                        <div className="empty-state">
                            <span className="spinner" aria-hidden="true"/>
                            <p className="eyebrow">A route worth stepping out for</p>
                            <h2>
                                {"Finding your next mile"
                                    if loading
                                    else "Opening the example"}
                            </h2>
                            <p>
                                {"We're matching your preferences to local landmarks. The first route can take longer while the model warms up."
                                    if loading
                                    else "Getting a feel for your next run."}
                            </p>
                        </div>
                    } elif connection_error {
                        <div className="error-state" role="alert">
                            <p className="eyebrow">Let's try that again</p>
                            <h2>We couldn't connect</h2>
                            <p>{connection_error}</p>
                            <p className="field-hint">
                                Your answers are saved in the form. Try Find my route again.
                            </p>
                        </div>
                    } elif plan is not None {
                        <RouteCard plan={plan}/>
                    } else {
                        <div className="empty-state">
                            <p className="eyebrow">02 / Meet your route</p>
                            <svg
                                className="route-art"
                                viewBox="0 0 360 240"
                                fill="none"
                                aria-hidden="true"
                            >
                                <path
                                    className="track-line"
                                    d="M70 174C15 116 81 17 155 52C214 79 174 154 228 176C292 202 335 91 275 65"
                                />
                                <path
                                    className="track-line track-inner"
                                    d="M83 162C40 118 91 39 149 68C201 94 158 169 221 190C299 222 357 80 282 48"
                                />
                                <circle cx="70" cy="174" r="11" fill="#d7ee9d"/>
                                <circle cx="70" cy="174" r="4" fill="#183e33"/>
                                <circle cx="275" cy="65" r="9" fill="#183e33"/>
                            </svg>
                            <h2>
                                Good things are
                                <br/>
                                just a run away.
                            </h2>
                            <p>
                                Your route will appear here with places to explore, a difficulty rating, and notes for the road.
                            </p>
                            <span className="empty-caption">
                                Your pace. Your place. Your next adventure.
                            </span>
                        </div>
                    }   }
                </section>
            </div>
            <section
                id="how-it-works"
                className="how-it-works"
                aria-labelledby="how-title"
            >
                <h2 id="how-title">A few answers. A fresh perspective.</h2>
                <div className="steps">
                    <div>
                        <span>01</span>
                        <h3>Set your rhythm</h3>
                        <p>
                            Choose your level, distance, neighborhood, and time of day.
                        </p>
                    </div>
                    <div>
                        <span>02</span>
                        <h3>Find your way</h3>
                        <p>
                            Get a loop through local landmarks, with difficulty and safety notes.
                        </p>
                    </div>
                    <div>
                        <span>03</span>
                        <h3>Take it outside</h3>
                        <p>
                            Open walking directions in Google Maps and check conditions before you go.
                        </p>
                    </div>
                </div>
            </section>
        </main>
        <footer className="shell">
            <span className="footer-brand">jogether.</span>
            <span>Run together, from your first mile.</span>
            <span>Always check your surroundings.</span>
        </footer>
    </div>
}

def:pub RouteCard(plan: RunPlan) -> JsxElement {
    route = plan.route;
    if route is None {
        return
            <div className="error-state" role="alert">
                <p className="eyebrow">A small detour</p>
                <h2>
                    {"Check your answers"
                        if not plan.accepted
                        else "No route this time"}
                </h2>
                <ul>
                    {for (i, err) in enumerate(plan.errors) {
                        <li key={str(i)}>{err}</li>
                    }}
                </ul>
                <p className="field-hint">
                    {"Update the form and try again."
                        if not plan.accepted
                        else "Try again, or preview the example route."}
                </p>
            </div>;
    }
    laps = route.laps if route.laps > 0 else 1;
    per_unit = 1.0 / 1.609344 if plan.unit == "mi" else 1.0;
    unit_name = "mi" if plan.unit == "mi" else "km";
    total = route.distance_km * per_unit;
    return
        <div className="route-card">
            <div className="route-heading">
                <p className="eyebrow">
                    {"Example route · hand-written"
                        if plan.is_example
                        else "02 / Your route is ready"}
                </p>
                <h2>{route.title}</h2>
                <p>
                    {"Preview only · this sample is independent of your preferences."
                        if plan.is_example
                        else f"Planned for you in {plan.seconds:.1f} seconds"}
                </p>
            </div>
            <dl className="route-stats">
                <div>
                    <dt>Distance</dt>
                    <dd>
                        {f"{total:.1f}"}
                        <span>{unit_name}</span>
                    </dd>
                </div>
                <div>
                    <dt>Difficulty</dt>
                    <dd>
                        {str(route.difficulty)}
                        <span>/ 5</span>
                    </dd>
                </div>
                <div>
                    <dt>Loop</dt>
                    <dd>
                        {str(laps)}
                        <span>{"lap" if laps == 1 else "laps"}</span>
                    </dd>
                </div>
            </dl>
            <p className="difficulty-reason">{route.difficulty_reason}</p>
            <h3 className="stops-title">Along the way</h3>
            <ol className="waypoints">
                {for (i, w) in enumerate(route.waypoints) {
                    <li key={str(i)}>
                        <span className="stop-number" aria-hidden="true">
                            {str(i + 1)}
                        </span>
                        <div>
                            <strong>{w.name}</strong>
                            <p>{w.note}</p>
                        </div>
                    </li>
                }}
            </ol>
            {if len(route.safety_notes) > 0 {
                <div className="safety-notes">
                    <h3>Before you head out</h3>
                    <ul>
                        {for (i, n) in enumerate(route.safety_notes) {
                            <li key={str(i)}>{n}</li>
                        }}
                    </ul>
                </div>
            }}
            {if plan.maps_url {
                <a
                    className="maps-button"
                    href={plan.maps_url}
                    target="_blank"
                    rel="noreferrer"
                >
                    {"Open one loop in Google Maps"
                        if laps > 1
                        else "Open this loop in Google Maps"}
                    <span aria-hidden="true">↗</span>
                </a>
            }}
            {if laps > 1 {
                <p className="lap-note">
                    {f"Repeat the {total / laps:.1f} {unit_name} loop {laps} times for the full distance."}
                </p>
            }}
        </div>;
}
