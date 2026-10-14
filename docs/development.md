# Week 3 implementation handoff

## Current scope

- `validate_request` checks the four answers (unchanged from week 2).
- `landmarks.jac` lists 8 draft landmarks per area (#4).
- `plan_route` is one ByLLM call that turns a request and that area's
  landmarks into a `RouteResult`. `generate_route` checks the output and
  retries once (#5).
- `jac run main.jac --generate` runs it on a local Ollama model. Without the
  flag, the CLI only validates, so CI never calls a model.

## Next slice

1. Field-check the landmark lighting and surfaces before the demo.
2. Compare models on the same requests and pick the default (#7).
3. Wrap `generate_route` in a `GenerateRoute` walker once the web-app layout
   lands (#3), then connect the form and result page (#6).

Sign-in and save/rate remain separate MVP work. Community and runner matching
remain after the route MVP.

## Progress tracking

For weekly slides, use one summary bullet, the actual Issue and PR links, and
their current status. Keep "implemented in a PR" separate from "merged".
