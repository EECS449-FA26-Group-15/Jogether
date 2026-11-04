# Issue #5 implementation and issue #4 handoff

## Available now

`GenerateRoute` in `route_agent.jac` accepts a `RunRequest` plus a server-owned
area-to-landmarks mapping and reports one typed `RouteResult`. It rechecks input
before calling the model and passes only the requested area's landmarks to
`propose_route`, the `by llm()` function. Do not expose the landmark mapping as
user-editable input when wiring a public endpoint.

Validation checks exact waypoint membership, difficulty 1–5, no more than three
safety notes, nonempty title/waypoints/notes/reason, and positive finite distance.
Both schema conversion failures and validation failures share a two-call budget.
The second call receives corrective feedback. A second failure raises `ValueError`
and reports no route. Provider/connection failures propagate rather than being
presented as a valid route. ByLLM output retries are disabled to avoid multiplying
the two-attempt budget.

## Pending issue #4

`route_contract.jac` is a temporary contract, not completion of issue #4. Its
`RouteResult` and `Waypoint` fields match that issue. When #4 lands:

1. Import its canonical result types instead of the temporary declarations;
   retain/move the `sem` descriptions so ByLLM sees field meanings.
2. Adapt `landmark_data.jac` to its actual data-file format if different.
3. Supply the curated 8–10 landmarks per area and run real-model checks for all
   three areas, runner levels and times of day.

No real landmark data or curated example route has been invented here. Tests use
fictional names beginning with `TEST`. The explicitly synthetic file at
`tests/fixtures/synthetic_landmarks.json` also supports a manual local-model smoke
test without waiting for #4; it is not production landmark data.

The provisional JSON format is a mapping from supported area names to lists:

```json
{
  "central-campus": [
    {
      "name": "<verified landmark name>",
      "description": "<curated description>",
      "lighting": "<known lighting or unknown>",
      "surface": "<known surface>",
      "good_time_of_day": "<curated time guidance>"
    }
  ]
}
```

This is a schema illustration, not usable route data. All five fields must be
nonempty strings. Missing/empty selected areas and duplicate landmark names fail
before calling the model. Only `central-campus`, `north-campus`, and `downtown`
are accepted. A file may temporarily contain fewer than all three areas; those
absent areas fail explicitly. Production data coverage belongs to #4.

## Local LLM setup

The call chain is Jac → ByLLM → local Ollama → `gemma3:4b`.
No API key is required for this local model. Install
[Ollama](https://docs.ollama.com/quickstart), then run:

```bash
ollama pull gemma3:4b
ollama serve  # separate terminal, only if the service is not already running
```

From the repository root, using the pinned Jac 0.37.25 installation:

```bash
jac install --frozen
jac run generate.jac --landmarks data/landmarks.json --level beginner --distance-km 2 --area central-campus --time-of-day morning
```

`data/landmarks.json` is the planned #4 file; it is not included yet. Substitute
the real path after that file is available. `jac run` still runs the original
input-only preview; it does not call the model. The generation CLI prints JSON
on success and exits with status 2 for invalid input, missing data or handled
generation failures.

To check the complete local-model/JSON-output flow before #4 is ready:

```bash
jac run generate.jac --landmarks tests/fixtures/synthetic_landmarks.json
```

All places in this fixture are fictional. The command calls the real configured
model; it is opt-in and is not run in CI. A successful result verifies the call
and output constraints, not actual geography or the factual accuracy of every
generated note.

The configured default is in `[byllm.model]` in `jac.toml`. Issue #7 can change it
after model comparisons; `BYLLM_DEFAULT_MODEL` can override it for a single shell.

On Windows, Jac runs inside WSL. Run Ollama in the same environment for the
simplest setup. If Ollama runs on Windows instead, verify that its endpoint is
reachable from WSL; Windows localhost and WSL localhost may differ. Do not assume
that a successful Windows `ollama list` proves WSL connectivity. No WSL/network
configuration is changed by this implementation.

On this Windows machine, installing dependencies in the D-drive checkout hit
Jac's 300-second pip timeout twice. Installing the same manifest in the WSL Linux
filesystem succeeded. The D-drive virtual environment is therefore incomplete;
use a checkout in the WSL Linux filesystem if the timeout recurs. The source and
lockfile do not depend on the temporary verification directory.

## Tests and limits

```bash
jac check main.jac routes.jac route_contract.jac route_agent.jac landmark_data.jac generate.jac tests/routes_tests.jac tests/agent_tests.jac tests/landmark_tests.jac
jac test -v
```

CI installs the locked ByLLM dependencies and uses `MockLLM`, exercising real
prompt construction and typed response parsing without Ollama or API credentials.
It verifies area isolation, walker reporting, invalid-input rejection, output
constraints, correction feedback and the two-call limit for malformed responses.

Real-model quality/latency is not established by these tests. Landmark membership
does not prove street connectivity, accurate distance or route safety. Results
are estimated itineraries until curated routes or a routing engine are added.

### Verification for this change

On October 12, 2026, with Jac 0.37.25 under WSL: all 9 Jac files passed type
and formatting checks, all 20 tests passed, and the invalid-input/missing-data
CLI checks returned exit code 2. `jac install --frozen` succeeded in a clean WSL
temporary checkout. At that point, no real LLM generation had been run.

On October 13, 2026, `gemma3:4b` was available through Ollama at
`http://localhost:11434` from WSL. A real-model smoke test exposed the CLI's use
of Python `dataclasses.asdict` on a Jac result. The CLI now explicitly serializes
the result fields, with a regression test covering model parsing through JSON
output. All 21 automated tests passed. The real-model CLI then exited with 0,
returning three allowed synthetic waypoints, difficulty 1 and one safety note.
This was a transport/schema smoke test, not a route-quality benchmark. Tests ran
in the existing WSL temporary checkout; the D-drive dependency limitation above
has not been resolved. Issue #4 integration and real-data validation remain open.
