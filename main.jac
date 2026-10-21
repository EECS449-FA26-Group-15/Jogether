"""Jogether web app: the route planner page plus its server endpoints.

Run `jac run` and open http://localhost:8000. The command-line preview lives in
cli.jac (`jac run --no-takeover cli.jac --generate`).
"""

import from planner { RunPlan, plan_run, sample_run }

import from .frontend { app as JogetherApp }

def:pub app -> JsxElement {
    <JogetherApp/>
}
