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

should_install_husky() {
  if [ "$HUSKY" = "0" ]; then
    return 1
  fi
  if is_cursor_cloud; then
    return 0
  fi
  if [ -n "$VERCEL" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$CI" ]; then
    return 1
  fi
  return 0
}

skip_husky() {
  echo "Skipping husky install ($1)"
}

install_husky() {
  if command -v husky >/dev/null 2>&1; then
    husky
    HUSKY_INSTALLED=1
  else
    skip_husky "husky not installed"
  fi
}

if should_install_husky; then
  install_husky
elif [ "$HUSKY" = "0" ]; then
  skip_husky "HUSKY=0"
else
  skip_husky "CI"
fi

# Best-effort at install time. On Cloud, agent-hooks may appear later — see
# session-ensure-git-hooks.sh (sessionStart) after one-time repo wiring.
sh "$(dirname "$0")/ensure-hooks.sh"

# Fresh git worktrees inherit core.hooksPath but not .husky/_ until husky runs here.
if [ "$HUSKY_INSTALLED" = "0" ] && should_install_husky && [ -f ".husky/pre-commit" ] && [ ! -x ".husky/_/pre-commit" ]; then
  echo "Husky shim missing in this worktree; re-running husky" >&2
  install_husky
fi

if [ "$HUSKY_INSTALLED" = "1" ]; then
  sh "$(dirname "$0")/verify-git-hooks.sh"
fi
