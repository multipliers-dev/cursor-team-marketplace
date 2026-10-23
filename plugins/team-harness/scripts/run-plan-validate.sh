#!/usr/bin/env sh
# Run the canonical plan validator against a consumer repository root without
# copying validator source. Uses the committed bundled .mjs (Node-only).
set -eu

die() {
  echo "error: $*" >&2
  exit 1
}

MIN_NODE_MAJOR=20

require_node() {
  if ! command -v node >/dev/null 2>&1; then
    die "Node.js ${MIN_NODE_MAJOR}+ is required (install Node or use the reusable GitHub Actions workflow). See plugins/team-harness/docs/centralized-consumption.md"
  fi
  major=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)
  if [ "$major" -lt "$MIN_NODE_MAJOR" ] 2>/dev/null; then
    die "Node.js ${MIN_NODE_MAJOR}+ is required (found $(node -v 2>/dev/null || echo unknown))"
  fi
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

resolve_plugin_root() {
  if [ -n "${TEAM_HARNESS_PLUGIN_ROOT:-}" ]; then
    printf '%s\n' "$TEAM_HARNESS_PLUGIN_ROOT"
    return 0
  fi

  candidate=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
  if [ -f "$candidate/dist/validate-plans.mjs" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  if [ -n "${CURSOR_PLUGIN_ROOT:-}" ] && [ -f "${CURSOR_PLUGIN_ROOT}/dist/validate-plans.mjs" ]; then
    printf '%s\n' "$CURSOR_PLUGIN_ROOT"
    return 0
  fi

  for base in \
    "${HOME}/.cursor/plugins/local" \
    "${HOME}/.cursor/plugins" \
    "/cursor/plugins" \
    ; do
    [ -d "$base" ] || continue
    # shellcheck disable=SC2044
    for bundle in $(find "$base" -maxdepth 7 -type f -path '*/dist/validate-plans.mjs' 2>/dev/null); do
      plugin_root=$(CDPATH= cd -- "$(dirname "$bundle")/.." && pwd)
      base_name=$(basename "$plugin_root")
      if [ "$base_name" = "team-harness" ]; then
        printf '%s\n' "$plugin_root"
        return 0
      fi
      if [ -f "$plugin_root/.cursor-plugin/plugin.json" ]; then
        name=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$plugin_root/.cursor-plugin/plugin.json" | head -n 1)
        if [ "$name" = "team-harness" ]; then
          printf '%s\n' "$plugin_root"
          return 0
        fi
      fi
    done
  done

  return 1
}

require_node

PLUGIN_ROOT=$(resolve_plugin_root) || die \
  "team-harness plugin not found on disk. Install the team-harness plugin from the cursor-team-marketplace team marketplace (Customize → Plugins), or set TEAM_HARNESS_PLUGIN_ROOT to the plugin directory. Do not copy validator source into this repo."

BUNDLE="$PLUGIN_ROOT/dist/validate-plans.mjs"
[ -f "$BUNDLE" ] || die "missing validator bundle at $BUNDLE (plugin install may be outdated — update team-harness from the marketplace)"

exec node "$BUNDLE" "$@"
