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

Install Jac:

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
```

Run the app from the repository root:

```bash
jac install
jac run
```

Setup for the mobile app, the CLI, and environment variables will be
documented here as they land.

## Status

Week 5. Project skeleton and wireframes in progress. MVP pitch: November 2.
Public launch: November 16.

## Team

- Yunqi Zhao
- Zhengjia Sun
- Zhongqi Huang
- Yufeng Wu
- Xinning Wang

## License

MIT
