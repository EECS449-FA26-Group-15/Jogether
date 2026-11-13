# Jogether

**Run together, from your first mile.**

Jogether is an AI running companion for students in Ann Arbor. Tell it how you
want to run today, and an agent plans a route that fits your level, rates its
difficulty, and flags what to watch out for. Then find people who run at your
pace and go together.

> Built by Group 15 for EECS 449: Generative and Agentic AI, University of
> Michigan, Fall 2026.

## The problem

Getting started with outdoor running is harder than it should be. New runners
don't know where to run, how far is reasonable, whether a route is safe at
night, or anyone to run with. Existing apps assume you already know all of
that.

## What Jogether does

**The hook: one sentence in, a route out.**

The web demo works today:

1. Answer four quick questions on the left: your level, distance, area, and
   time of day. The map on the right is live from the start.
2. Optionally double-click the map to pin where you start, or type an
   address, and add a wish in your own words, like "I'd like to run along the
   river".
3. Tap **Show me three routes**. Code measures candidate routes from landmarks
   that suit your time of day; an LLM agent describes the three best, rates
   each one's difficulty, and writes safety notes.
4. Three short route blocks appear under the form. Tap one to draw it on the
   map, read every stop, and open it in Google Maps.

Still to come for the MVP: sign in with your umich.edu email, then save, run,
and rate your routes.

**Coming next: the community layer.**

- Experienced runners post their favorite routes; the agent rates and tags them.
- Match with runners at a similar pace and schedule, and invite them to a run.

## Tech stack

- [Jac / Jaseci](https://www.jaseci.org/) for the server, web app, and mobile app
  sharing one core
- ByLLM for the route-planning agent
- Development tracked in [Flowline](https://github.com/kashmithnisakya/flowline);
  every issue and pull request moves through our board

## Getting started

Install the Jac version tested by this prototype (0.37.25):

```bash
# Linux or Apple Silicon macOS; Windows users can use WSL2.
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) JAC_PLATFORM=linux-x86_64 ;;
  Linux-aarch64) JAC_PLATFORM=linux-aarch64 ;;
  Darwin-arm64) JAC_PLATFORM=macos-aarch64 ;;
  *) echo "This release has no binary for this platform"; exit 1 ;;
esac
JAC_ASSET="jac-0.37.25-$JAC_PLATFORM"
JAC_URL="https://github.com/jaseci-labs/jac/releases/download/v0.37.25/$JAC_ASSET"
mkdir -p .jac/bin
curl -fL --retry 3 "$JAC_URL" -o ".jac/bin/$JAC_ASSET" || exit 1
curl -fL --retry 3 "$JAC_URL.sha256" -o ".jac/bin/$JAC_ASSET.sha256" || exit 1
(cd .jac/bin && shasum -a 256 -c "$JAC_ASSET.sha256") || exit 1
mv ".jac/bin/$JAC_ASSET" .jac/bin/jac
chmod +x .jac/bin/jac
export PATH="$PWD/.jac/bin:$PATH"
```

### Run the web demo

On this Windows checkout, start Ollama, then run `./start-demo.ps1` in
PowerShell. The launcher uses the pinned Jac compiler through WSL and starts
the web app in development mode. It copies source into `~/.cache/jogether-demo`
inside WSL so dependency installation does not suffer from slow Windows-mounted
filesystem access. Restart the launcher after editing the Windows source.
Open the localhost URL printed by Jac.
The model is `gemma3:4b` via Ollama; no cloud API key is required.

The November 4 local integration uses remote `feat/web-demo` at `ca020f2`.
Previous local source files were backed up to the sibling directory
`Jogether-backup-20261104`. The older `generate.jac` command remains available
with `jac run --no-takeover generate.jac --landmarks <file>`.

Route generation runs on [Ollama](https://ollama.com/download) with
`gemma3:4b` (set in `jac.toml`; the final model is chosen in issue #7).
No API key is needed:

```bash
ollama pull gemma3:4b
jac install
jac run
```

Open http://localhost:8000, answer the questions, and tap **Show me three
routes**. The first request loads the model into memory and takes longer; after
that three routes take about 8 to 15 seconds on an Apple Silicon laptop.

If `jac install` hangs while installing the web packages (seen on networks with
broken IPv6), stop it and install them with npm instead, then run `jac run`:

```bash
NODE_OPTIONS="--dns-result-order=ipv4first" npm install --prefix .jac/client
```

How a route is planned:

1. If the runner wrote a note, one LLM call turns it into structured
   preferences: wanted and avoided landmark tags (river, park, quiet, ...),
   "avoid hills", and a route shape. Empty notes skip this call.
2. Code builds the landmark pool: the chosen area's landmarks plus any landmark
   from a neighbouring area within reach of the requested distance, filtered
   for the time of day, with dirt trails dropped for beginners. The chosen
   start landmark is always in the pool.
3. Code measures candidate routes from that pool (`geo.jac`) in three shapes:
   a loop back to the start, an out-and-back, or a one-way run that ends
   elsewhere. Each candidate is scored on distance, uphill metres, matched
   preferences and shape; repeating a loop for laps is only a fallback and is
   penalised. The 3 best candidates with different stops become the options.
4. One LLM call describes every option, best fit for the runner's level, time
   of day and own words first: a title, a note per stop, the difficulty and
   the safety notes for each. A pick that names a missing option, repeats one,
   or fails the output check is dropped, so the page shows one to three routes.
5. The distance and climb on each card come from step 3, not from the LLM. Leg
   lengths are real walking distances from the OSRM foot router on
   OpenStreetMap, elevation is from Open-Meteo, so the card agrees with a
   walking-directions check to within about 0.1 mile. The Google Maps link
   shows one pass of the route.
6. Each route comes with its geometry (`maps.jac`): the server asks the OSRM
   foot router for the walking path through the stops and sends the line and
   the numbered stops to the page. The page draws the chosen route with
   Leaflet over OpenStreetMap tiles, in a map that can be panned and zoomed
   from the start. If the router does not answer, the line is drawn straight
   from stop to stop and the route block says so. The route block also lists
   every stop, the safety notes and the Google Maps link.

The start is a point of the runner's own: either pinned by double-clicking
the map, or typed as an address. For an address the server asks the US Census
geocoder first (it knows house numbers), then OpenStreetMap Nominatim with the
address as typed and shorter forms of it (dropping extra street words, then
the house number), so at least the street is found; the note above the route
blocks says which. The point becomes a place of its own: one OSRM table call
gives its walking distances to every landmark (straight-line estimates if that
fails), Open-Meteo its elevation (the nearest landmark's if that fails). It
must be within 2 km of a landmark we know, and the area switches to that
landmark's area. An address that cannot be found, or a point too far out, is
reported back instead of planning. Leave both blank to start anywhere in the
area.

At run time the server talks to the US Census geocoder and Nominatim (only
when an address is typed), the OSRM foot router (table and route services),
Open-Meteo, and the standard OpenStreetMap tile server for the map pictures.
Keep the demo's traffic light; the tile server's usage policy does not allow
heavy automated use.

Landmark data (46 landmarks across the three areas, coordinates, 1035 walking
distances, elevations) is generated: edit `tools/landmark_seed.py`, then run
`python3 tools/build_geo.py` to rewrite `landmarks.jac` and `geo_data.jac`.

The page takes distance in miles or km; it is converted to km for planning.

If the server reports `IndexError` from `get_mtir` right after a fresh start,
a stale prepared-app snapshot is being reused after a function signature
changed. Stop the server, delete `.jac/cache/applications`, and run `jac run`
again.

Each route is checked (known landmarks, 1 to 6 waypoints, difficulty 1-5, at
most 3 safety notes) and regenerated once if it fails. If both attempts fail, the page says so and
offers the hand-written example route, clearly labelled as an example. The
landmark list is a draft: check lighting and surface on the ground before
trusting the safety notes.

### Command-line preview

The same planner runs from the terminal through `cli.jac`. Without
`--generate` it only validates the answers, so it needs no model.
`--no-takeover` runs the file on its own instead of as the web app:

```bash
jac run --no-takeover cli.jac
jac run --no-takeover cli.jac --level intermediate --distance-km 5 --area north-campus --time-of-day evening
jac run --no-takeover cli.jac --distance-km 0
jac run --no-takeover cli.jac --generate
```

The default preview accepts a beginner's 2 km request for central campus in
the morning. An invalid answer, such as a 0 km distance, prints an error and
exits with code 2. With `--generate`, the command exits with code 1 if both
attempts fail.

Initial prototype options:

- Level: `beginner`, `intermediate`, `experienced`
- Distance: finite number from 0.5 to 10 km, including both boundaries
- Area: `central-campus`, `north-campus`, `downtown`
- Time: `morning`, `afternoon`, `evening`
- Start (optional): the exact name of a landmark from `landmarks.jac`
- Shape (optional): `any`, `loop`, `out-and-back`, `one-way`

These options and bounds are initial product assumptions, not verified route
coverage, a medical recommendation, or a safety guarantee. Keep the form in
sync with `routes.jac` when the team changes them.

Check the code and run the tests:

```bash
jac check main.jac planner.jac frontend.jac cli.jac routes.jac geo.jac landmarks.jac tests/routes_tests.jac tests/landmarks_tests.jac tests/route_agent_tests.jac tests/planner_tests.jac tests/geo_tests.jac
jac fmt --check main.jac planner.jac frontend.jac cli.jac routes.jac geo.jac landmarks.jac tests/routes_tests.jac tests/landmarks_tests.jac tests/route_agent_tests.jac tests/planner_tests.jac tests/geo_tests.jac
jac test -v
```

| File | What it does |
|---|---|
| `main.jac` | Web app entry: serves the page and its endpoints |
| `frontend.jac` | The page: the questions and route blocks on the left, the Leaflet map on the right (double-click pins the start), and the progress bar on the button |
| `planner.jac` | Endpoints the page calls: `plan_run` (pin or address to start, three routes with geometry) and `sample_run`, plus the Google Maps link |
| `routes.jac` | Request validation, the `RouteResult` shape, the ByLLM route calls (`plan_routes` for the page, `plan_route` for the CLI) and the output check |
| `geo.jac` | Landmark coordinates, measured loop distances, and the candidate loops the LLM describes |
| `maps.jac` | Route geometry for the map: the OSRM walking path and the numbered stops as coordinates |
| `landmarks.jac` | The curated landmark list |
| `cli.jac` | Command-line preview of the same planner |

Tests use a mocked LLM, so CI never calls a real model.

Authentication, the mobile UI, and save/rate are not implemented yet. See
[the development notes](docs/development.md) for the next handoff.

## Status

Course week 8 (October 21): clickable web demo running on a local open-weight
model. MVP pitch (Group 15): November 4. Public launch: November 16.

## Team

- Yunqi Zhao
- Zhengjia Sun
- Zhongqi Huang
- Yufeng Wu
- Xinning Wang

## License

MIT
