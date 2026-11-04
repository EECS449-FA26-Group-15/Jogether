# Local web demo — verified November 4, 2026

Model: Ollama `gemma3:4b` (installed model reports 3.9B parameters, Q4_K_M).
Jac: 0.37.25. Web source integrated from `origin/feat/web-demo` at `ca020f2`.

## Start on this Windows machine

For a fresh clone, install Jac 0.37.25 using the README instructions first
(inside WSL on Windows). The compiler may be in `.jac/bin/jac` or on PATH;
`.jac/` is not included in Git. Install Ollama and run `ollama pull gemma3:4b`.
Check that `curl http://localhost:11434/api/tags` works from the shell running
Jac. On macOS/Linux, use `bash ./run-demo.sh` instead of the PowerShell launcher.
The launcher installs project dependencies but does not install Jac or Ollama.
Only Windows + WSL has been verified locally.

Keep Ollama running. In PowerShell:

```powershell
cd D:\UMICH\EECS449\Jogether
.\start-demo.ps1
```

Open the **App** URL printed by Jac, not its separate API URL. The verified
session used http://localhost:8003/ (API on 8002); ports can change if occupied.
Stop with Ctrl+C. The launcher copies source to `~/.cache/jogether-demo` in WSL
and installs dependencies there. Restart it after changing the Windows source.
Do not start a second copy while the first is still running.

## Verification

- Whole-app `jac check`: passed, with existing compiler warnings.
- `jac test -v`: 47 passed, including the preserved route-agent tests.
- `bash tests/cli_checks.sh`: passed invalid-input and missing-data checks.
- `jac fmt --check frontend.jac`: passed.
- Browser: real generation for Beginner, 2 miles, North Campus, Morning
  returned **Engineering Loop**, approximately 3.1 km, difficulty 2/5,
  six landmarks, safety notes and a Google Maps loop link in **6.8 seconds**.
- Screenshot: `.jac/demo-verified.png`; test log: `.jac/verified-tests.log`.

The frontend now restores its button after a failed RPC and shows a connection
error. The older independent generation CLI remains available with
`jac run --no-takeover generate.jac --landmarks <file>`.

This is a local demonstration, not a public deployment. Sign-in, saving,
ratings and runner matching are still outside this demo. Map-link rendering
was checked; the Google Maps route and real-world path were not field-verified.
Older issue #5 handoff notes describe the previous standalone implementation;
the web app uses `routes.jac`, `planner.jac`, `geo.jac` and `landmarks.jac`.

The previous local source is preserved in `../Jogether-backup-20261104`.
