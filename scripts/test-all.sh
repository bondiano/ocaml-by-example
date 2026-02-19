#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Running all tests..."
for dir in exercises/chapter*/; do
  if [ -f "$dir/dune-project" ]; then
    echo "  Testing $dir..."
    (cd "$dir" && dune runtest) || true
  fi
done

echo "==> Done."
