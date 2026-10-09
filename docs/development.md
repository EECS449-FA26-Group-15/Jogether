# Week 2 implementation handoff

## Current scope

The CLI exercises the four answers from the route-first MVP. The reusable
`validate_request` function returns a typed `ValidationResult` containing
`accepted`, all field errors, and the original `RunRequest`.

Successful CLI previews exit with code 0. Invalid requests exit with code 2.
No database, credentials, LLM call, or mapping service is involved. There are
no route waypoints or generated safety notes yet.

## Next slice

1. Review the input options and 0.5–10 km prototype bounds with the team.
2. Reuse this validation in the four-question web form and Jac API walker.
3. Add a typed route response and ByLLM call grounded in verified route data.
   Include waypoint provenance, difficulty rationale, and time-specific notes.

Sign-in and save/rate remain separate MVP work. Community and runner matching
remain after the route MVP.

## Review and progress tracking

Current stage: ready for code review once the PR opens. A maintainer reviews
the request contract and setup steps, then merges after checks pass.
The team should track the issue and PR in its own Flowline board. This change
does not create a board or assign work to team members.

For later weekly slides, use one summary bullet, the actual Issue and PR
links, and their current status. Keep “implemented in a PR” separate from
“merged” and distinguish the local request demo from route generation.
