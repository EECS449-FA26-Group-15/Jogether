# Week 3 implementation handoff

## Current scope

- `validate_request` checks the four answers (unchanged from week 2).
- `landmarks.jac` lists 8 draft landmarks per area (#4).
- `plan_route` is one ByLLM call that turns a request and that area's
  landmarks into a `RouteResult`. `generate_route` checks the output and
  retries once (#5).
- `jac run --no-takeover cli.jac --generate` runs it on a local Ollama model. Without the
  flag, the CLI only validates, so CI never calls a model.
- Week 8 demo: the repo is now a Jac web app. `jac run` serves the page in
  `frontend.jac`, which calls `plan_run` in `planner.jac`. Before the LLM call,
  landmarks are filtered by time of day, and the check now caps a route at 6
  waypoints. The request also carries an optional free-text wish (`notes`).

## Next slice

1. Field-check the landmark lighting and surfaces.
2. Compare models on the same requests and pick the default (#7).
3. Finish #3 and #6 on top of the demo page: real styling, mobile layout,
   and a loading state that survives a slow first model call.

Sign-in and save/rate remain separate MVP work. Community and runner matching
remain after the route MVP.

## Progress tracking

For weekly slides, use one summary bullet, the actual Issue and PR links, and
their current status. Keep "implemented in a PR" separate from "merged".
