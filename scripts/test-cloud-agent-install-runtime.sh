#!/usr/bin/env sh
# Runtime smoke test for cloud-agent-install.sh Node prefix extraction.
# Installs into a temp prefix (not /usr/local), verifies node/npm/npx, and that
# the declared dependency command runs. Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
INSTALL_SH="$ROOT/plugins/team-harness/scripts/cloud-agent-install.sh"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl required for cloud-agent-install runtime test" >&2
  exit 1
fi

current_node_major() {
  if command -v node >/dev/null 2>&1; then
    node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1
    return 0
  fi
  printf ''
}

CURRENT=$(current_node_major)
case "$CURRENT" in
  20) TARGET_MAJOR=22 ;;
  22) TARGET_MAJOR=20 ;;
  '') TARGET_MAJOR=20 ;;
  *) TARGET_MAJOR=20 ;;
esac

WORKDIR=$(mktemp -d)
PREFIX="$WORKDIR/prefix"
MARKER="$WORKDIR/install-ran"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$PREFIX"
printf 'v%s\n' "$TARGET_MAJOR" >"$WORKDIR/.nvmrc"

export CLOUD_AGENT_NODE_PREFIX="$PREFIX"
# Keep system tools but avoid an existing /usr/local Node shadowing the mismatch check.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

cd "$WORKDIR"
sh "$INSTALL_SH" touch "$MARKER"

if [ ! -f "$MARKER" ]; then
  echo "error: declared install command did not run" >&2
  exit 1
fi

NODE_BIN="$PREFIX/bin"
export PATH="$NODE_BIN:$PATH"

for tool in node npm npx; do
  if [ ! -e "$NODE_BIN/$tool" ]; then
    echo "error: missing $NODE_BIN/$tool after install" >&2
    exit 1
  fi
done

INSTALLED_MAJOR=$("$NODE_BIN/node" -v | sed 's/^v//' | cut -d. -f1)
if [ "$INSTALLED_MAJOR" != "$TARGET_MAJOR" ]; then
  echo "error: expected Node major ${TARGET_MAJOR}, got ${INSTALLED_MAJOR}" >&2
  exit 1
fi

"$NODE_BIN/node" -v >/dev/null
"$NODE_BIN/npm" -v >/dev/null
"$NODE_BIN/npx" --version >/dev/null

if [ ! -d "$PREFIX/lib/node_modules/npm" ]; then
  echo "error: npm lib tree missing under ${PREFIX}/lib/node_modules/npm" >&2
  exit 1
fi

echo "ok cloud-agent-install runtime (Node v${INSTALLED_MAJOR}, npm tree present, declared command ran)"
