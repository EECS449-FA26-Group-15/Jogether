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

1. Answer four quick questions: your level, distance, area, and time of day.
2. Optionally add a wish in your own words, like "I'd like to run along the river".
3. Tap **Generate**. An LLM agent picks landmarks that suit your time of day,
   orders them into a route, rates its difficulty, and writes safety notes.
4. Open the route in Google Maps.

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

Route generation runs on [Ollama](https://ollama.com/download) with
`gemma3:4b` (set in `jac.toml`; the final model is chosen in issue #7).
No API key is needed:

```bash
ollama pull gemma3:4b
jac install
jac run
```

Open http://localhost:8000, answer the questions, and tap **Generate my
route**. The first request loads the model into memory and takes longer; after
that a route takes a few seconds on an Apple Silicon laptop.

If `jac install` hangs while installing the web packages (seen on networks with
broken IPv6), stop it and install them with npm instead, then run `jac run`:

```bash
NODE_OPTIONS="--dns-result-order=ipv4first" npm install --prefix .jac/client
```

The agent may only use landmarks for the chosen area from `landmarks.jac`, and
only those that suit the chosen time of day. Each route is checked (known
landmarks, 1 to 6 waypoints, difficulty 1-5, at most 3 safety notes) and
regenerated once if it fails. If both attempts fail, the page says so and
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

These options and bounds are initial product assumptions, not verified route
coverage, a medical recommendation, or a safety guarantee. Keep the form in
sync with `routes.jac` when the team changes them.

Check the code and run the tests:

```bash
jac check main.jac planner.jac frontend.jac cli.jac routes.jac landmarks.jac tests/routes_tests.jac tests/landmarks_tests.jac tests/route_agent_tests.jac tests/planner_tests.jac
jac fmt --check main.jac planner.jac frontend.jac cli.jac routes.jac landmarks.jac tests/routes_tests.jac tests/landmarks_tests.jac tests/route_agent_tests.jac tests/planner_tests.jac
jac test -v
```

| File | What it does |
|---|---|
| `main.jac` | Web app entry: serves the page and its endpoints |
| `frontend.jac` | The page: the four questions, the Generate button, the route card |
| `planner.jac` | Endpoints the page calls: `plan_run` and `sample_run`, plus the Google Maps link |
| `routes.jac` | Request validation, the `RouteResult` shape, the ByLLM route call and its output check |
| `landmarks.jac` | The curated landmark list |
| `cli.jac` | Command-line preview of the same planner |

Tests use a mocked LLM, so CI never calls a real model.

Authentication, the mobile UI, and save/rate are not implemented yet. See
[the development notes](docs/development.md) for the next handoff.

## Status

Course week 8 (October 21): clickable web demo running on a local open-weight
model. MVP pitch: November 2. Public launch: November 16.

## Team

- Yunqi Zhao
- Zhengjia Sun
- Zhongqi Huang
- Yufeng Wu
- Xinning Wang

## License

MIT
