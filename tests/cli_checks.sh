#!/usr/bin/env bash
set -euo pipefail

expect_input_error() {
  set +e
  "$@"
  result=$?
  set -e
  if [ "$result" -ne 2 ]; then
    echo "Expected exit 2, got $result" >&2
    exit 1
  fi
}

expect_input_error jac run --no-takeover cli.jac --distance-km 0
expect_input_error jac run --no-takeover generate.jac --landmarks .jac/nonexistent-landmarks.json
