#!/usr/bin/env bash
set -euo pipefail
source_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="${XDG_CACHE_HOME:-$HOME/.cache}/jogether-demo"
mkdir -p "$runtime_dir"
# Keep dependencies on the Linux filesystem; Windows-mounted site-packages is slow.
tar -C "$source_dir" --exclude=.git --exclude=.jac --exclude=.venv -cf - . | tar -C "$runtime_dir" -xf -
export PATH="$source_dir/.jac/bin:$PATH"
cd "$runtime_dir"
if [[ ! -f .jac/demo-installed ]] || ! cmp -s jac.toml .jac/demo-installed; then
    jac install
    cp jac.toml .jac/demo-installed
fi
exec jac run --dev main.jac
