#!/usr/bin/env sh
# Verify Husky's shim layout exists in the current Git worktree.
# Fresh `git worktree add` checkouts inherit core.hooksPath but not .husky/_ until prepare runs.
set -e

if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

cd "$REPO_ROOT"

if [ ! -f ".husky/pre-commit" ]; then
  exit 0
fi

if [ -x ".husky/_/pre-commit" ]; then
  exit 0
fi

echo "error: Husky hook shim missing in this worktree (.husky/_/pre-commit)." >&2
echo "Run: npm run prepare" >&2
exit 1
