#!/usr/bin/env sh
# Rebuild the committed validator bundle and fail if the artifact drifted.
set -eu
cd "$(dirname "$0")/.."

if [ ! -d node_modules/esbuild ]; then
  echo "error: run npm ci before check:validator-bundle-drift" >&2
  exit 1
fi

npm run build:validator
git diff --exit-code -- plugins/team-harness/dist/validate-plans.mjs
echo "ok validator bundle drift check"
