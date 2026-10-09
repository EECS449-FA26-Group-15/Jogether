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

**The MVP: four answers in, one route out.**

1. Sign in with your umich.edu email.
2. Answer four quick questions: your level, distance, area, and time of day.
3. Tap **Generate**. An LLM agent reasons over your constraints and local
   geography and returns a route, a difficulty rating, and safety notes.
4. Save it, run it, and rate it afterwards.

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

Run the local request demo from the repository root. No API key, external
service, or database is required:

```bash
jac run
```

The default demo accepts a beginner's 2 km request for central campus in the
morning and prints JSON with `accepted: true` and `route_generated: false`.
Try different answers:

```bash
jac run main.jac --level intermediate --distance-km 5 --area north-campus --time-of-day evening
jac run main.jac --distance-km 0
```

The second command prints a distance error and exits with code 2.
Malformed CLI arguments also exit with code 2. A successful preview only
validates the request; it does not recommend a route or assess safety.

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
jac check main.jac routes.jac tests/routes_tests.jac
jac fmt --check main.jac routes.jac tests/routes_tests.jac
jac test -v
```

`main.jac` handles the CLI. `routes.jac` defines the typed request/result and
shared validation function, ready for reuse by the future web form and
ByLLM route call. Tests cover accepted choices, distance boundaries,
NaN/infinity, invalid options, and reporting all errors together.

Authentication, the web/mobile UI, route generation, and save/rate are not
implemented in this prototype. See [the development notes](docs/development.md)
for the next handoff.

## Status

Project week 2 (October 7, course week 6): local Jac request prototype ready
for review. MVP pitch: November 2. Public launch: November 16.

## Team

- Yunqi Zhao
- Zhengjia Sun
- Zhongqi Huang
- Yufeng Wu
- Xinning Wang

## License

MIT
