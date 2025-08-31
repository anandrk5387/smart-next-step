#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [compile] Compiling TypeScript..."
if ! command -v npx &>/dev/null; then
  echo "  npx not found; ensure Node.js/npm are installed."
  exit 1
fi

npx tsc
echo "🔹 [compile] TypeScript compiled to dist/."
