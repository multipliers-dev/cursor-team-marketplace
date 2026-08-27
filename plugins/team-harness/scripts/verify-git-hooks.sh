#!/usr/bin/env sh
# Verify Husky's shim layout exists in the current Git worktree.
# Fresh `git worktree add` checkouts inherit core.hooksPath but not .husky/_ until prepare runs.
set -e

if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$REPO_ROOT"

[ -d .husky ] || exit 0

missing=0
for hook_script in .husky/*; do
  [ -f "$hook_script" ] || continue
  hook_name=$(basename "$hook_script")
  case "$hook_name" in
    _ | husky.sh | .gitignore | README*) continue ;;
  esac
  if [ ! -x ".husky/_/$hook_name" ]; then
    echo "error: Husky hook shim missing or not executable in this worktree (.husky/_/$hook_name)." >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Run: npm run prepare" >&2
  exit 1
fi
