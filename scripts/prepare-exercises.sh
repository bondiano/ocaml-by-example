#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Preparing exercises (clearing my_solutions.ml in all chapters)..."

for f in exercises/chapter*/test/my_solutions.ml exercises/appendix_*/test/my_solutions.ml; do
  if [ -f "$f" ]; then
    cat > "$f" <<'EOF'
(** Здесь вы можете писать свои решения упражнений. *)
EOF
    echo "  Cleared: $f"
  fi
done

echo "==> Done."
