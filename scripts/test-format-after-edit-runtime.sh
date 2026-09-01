#!/usr/bin/env sh
# Runtime smoke: format-after-edit is path-safe and fail-open.
# Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
FORMAT="$ROOT/plugins/team-harness/scripts/format-after-edit.sh"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: missing required command: $1" >&2
    exit 1
  }
}

require_cmd git
require_cmd sh

WORKDIR=$(mktemp -d)
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

cd "$WORKDIR"
git init -b main >/dev/null
git config user.email "format-after-edit-test@localhost"
git config user.name "Format After Edit Test"

mkdir -p scripts
cat > scripts/ensure-hooks.sh <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x scripts/ensure-hooks.sh

outside="$WORKDIR/outside-repo.md"
printf 'x\n' > "$outside"

# Path outside repo must be ignored (fail-open, no error).
if ! sh "$FORMAT" "$outside" >/dev/null 2>&1; then
  echo "error: format-after-edit must fail open on paths outside repo" >&2
  exit 1
fi

# In-repo path must not crash even when prettier is absent.
printf 'x\n' > in-repo.txt
if ! sh "$FORMAT" in-repo.txt >/dev/null 2>&1; then
  echo "error: format-after-edit must fail open on unsupported extensions" >&2
  exit 1
fi

printf 'x\n' > in-repo.md
if ! sh "$FORMAT" in-repo.md >/dev/null 2>&1; then
  echo "error: format-after-edit must fail open when prettier is unavailable" >&2
  exit 1
fi

echo "ok format-after-edit runtime (outside-repo ignored, fail-open in-repo)"
