#!/usr/bin/env sh
# Portable Cloud-aware prepare (team-harness marketplace primitive).
# Install git hooks for local + Cursor Cloud; skip on Vercel / GitHub Actions / CI.
# Cursor Cloud VMs may set CI=true, so CI alone is not enough to skip.
# Default On does not invoke this — wire package.json "prepare" per repo.
set -e

HUSKY_INSTALLED=0

is_cursor_cloud() {
  [ -d "${HOME}/.cursor/agent-hooks" ] || [ -S "${CURSOR_AGENT_SOCKET:-/run/cursor/api.sock}" ]
}

skip_husky() {
  echo "Skipping husky install ($1)"
}

should_install_husky() {
  if [ "$HUSKY" = "0" ]; then
    skip_husky "HUSKY=0"
    return 1
  fi
  if is_cursor_cloud; then
    return 0
  fi
  if [ -n "$VERCEL" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$CI" ]; then
    skip_husky "CI"
    return 1
  fi
  if ! command -v husky >/dev/null 2>&1; then
    skip_husky "husky not installed"
    return 1
  fi
  return 0
}

install_husky() {
  husky
  HUSKY_INSTALLED=1
}

needs_husky_shim_repair() {
  [ -f .husky/pre-commit ] && [ ! -f .husky/_/pre-commit ]
}

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)

if should_install_husky; then
  if command -v husky >/dev/null 2>&1; then
    install_husky
  else
    skip_husky "husky not installed"
  fi
fi

# Fresh worktrees inherit core.hooksPath=.husky/_ but not the generated .husky/_ shims.
if needs_husky_shim_repair; then
  if command -v husky >/dev/null 2>&1; then
    install_husky
  fi
fi

if [ "$HUSKY_INSTALLED" = "1" ]; then
  sh "$SCRIPT_DIR/verify-git-hooks.sh"
fi

# Best-effort at install time. On Cloud, agent-hooks may appear later — see
# session-ensure-git-hooks.sh (sessionStart) after one-time repo wiring.
sh "$SCRIPT_DIR/ensure-hooks.sh"
