#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Building all exercise packages..."
for dir in exercises/chapter*/ exercises/appendix_*/; do
  if [ -f "$dir/dune-project" ]; then
    echo "  Building $dir..."
    (cd "$dir" && dune build)
  fi
done

echo "==> Building book..."
mdbook build

echo "==> Done."
