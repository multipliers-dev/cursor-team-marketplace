#!/usr/bin/env sh
# Run the canonical plan validator against a consumer repository root without
# copying validator source into the consumer. Resolves the installed team-harness
# plugin (or TEAM_HARNESS_PLUGIN_ROOT) and invokes validate-plans.ts with npx.
set -eu

die() {
  echo "error: $*" >&2
  exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

resolve_plugin_root() {
  if [ -n "${TEAM_HARNESS_PLUGIN_ROOT:-}" ]; then
    printf '%s\n' "$TEAM_HARNESS_PLUGIN_ROOT"
    return 0
  fi

  candidate=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
  if [ -f "$candidate/scripts/validate-plans.ts" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  if [ -n "${CURSOR_PLUGIN_ROOT:-}" ] && [ -f "${CURSOR_PLUGIN_ROOT}/scripts/validate-plans.ts" ]; then
    printf '%s\n' "$CURSOR_PLUGIN_ROOT"
    return 0
  fi

  # Heuristic search for marketplace-installed team-harness (paths vary by host; see centralized-consumption.md).
  for base in \
    "${HOME}/.cursor/plugins/local" \
    "${HOME}/.cursor/plugins" \
    "/cursor/plugins" \
    ; do
    [ -d "$base" ] || continue
    # shellcheck disable=SC2044
    # shellcheck disable=SC2044
    for cli in $(find "$base" -maxdepth 6 -type f -path '*/scripts/validate-plans.ts' 2>/dev/null); do
      plugin_root=$(CDPATH= cd -- "$(dirname "$cli")/.." && pwd)
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

PLUGIN_ROOT=$(resolve_plugin_root) || die \
  "team-harness plugin not found on disk. Install the team-harness plugin from the cursor-team-marketplace team marketplace (Customize → Plugins), or set TEAM_HARNESS_PLUGIN_ROOT to the plugin directory. Do not copy validator source into this repo."

CLI="$PLUGIN_ROOT/scripts/validate-plans.ts"
[ -f "$CLI" ] || die "missing validator CLI at $CLI (plugin install may be incomplete)"

if ! command -v node >/dev/null 2>&1; then
  die "Node.js is required to run plan validation (install Node 20+ or use the reusable GitHub Actions workflow). See plugins/team-harness/docs/centralized-consumption.md"
fi

if ! command -v npx >/dev/null 2>&1; then
  die "npx is required to run plan validation (install Node/npm or use the reusable GitHub Actions workflow)"
fi

exec npx --yes -p "tsx@^4.23.13" -p "yaml@^2.8.1" tsx "$CLI" "$@"
