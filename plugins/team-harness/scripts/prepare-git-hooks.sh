#!/usr/bin/env sh
# Portable Cloud-aware prepare (team-harness marketplace primitive).
# Install git hooks for local + Cursor Cloud; skip on Vercel / GitHub Actions / CI.
# Cursor Cloud VMs may set CI=true, so CI alone is not enough to skip.
# Default On does not invoke this — wire package.json "prepare" per repo.
set -e

is_cursor_cloud() {
  [ -d "${HOME}/.cursor/agent-hooks" ] || [ -S "${CURSOR_AGENT_SOCKET:-/run/cursor/api.sock}" ]
}

skip_husky() {
  echo "Skipping husky install ($1)"
}

if [ "$HUSKY" = "0" ]; then
  skip_husky "HUSKY=0"
elif is_cursor_cloud; then
  if command -v husky >/dev/null 2>&1; then
    husky
  else
    skip_husky "husky not installed"
  fi
elif [ -n "$VERCEL" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$CI" ]; then
  skip_husky "CI"
elif command -v husky >/dev/null 2>&1; then
  husky
else
  skip_husky "husky not installed"
fi

# Best-effort at install time. On Cloud, agent-hooks may appear later — see
# session-ensure-git-hooks.sh (sessionStart) after one-time repo wiring.
sh "$(dirname "$0")/ensure-hooks.sh"
