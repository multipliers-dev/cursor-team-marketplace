#!/usr/bin/env sh
# Portable Husky shim verifier (team-harness marketplace primitive).
# Fails when core.hooksPath points at .husky/_ but generated shims are missing
# (common after git worktree add before npm run prepare).
# Default On does not invoke this — wire package.json "verify:git-hooks" per repo.
set -e

if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi

HOOKS_PATH=$(git -C "$REPO_ROOT" config --get core.hooksPath 2>/dev/null || true)
case "$HOOKS_PATH" in
  .husky/_|.husky/_/*|*/.husky/_) ;;
  *)
    exit 0
    ;;
esac

missing=0
for hook_script in "$REPO_ROOT"/.husky/pre-* "$REPO_ROOT"/.husky/commit-msg; do
  [ -f "$hook_script" ] || continue
  hook_name=$(basename "$hook_script")
  if [ ! -f "$REPO_ROOT/.husky/_/$hook_name" ]; then
    echo "error: missing Husky shim .husky/_/$hook_name (git hooks will silently skip)" >&2
    echo "hint: run npm run prepare (or npm run verify:git-hooks after prepare succeeds)" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi
