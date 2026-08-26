#!/usr/bin/env sh
# Runtime smoke test for interview-repo-bootstrap.sh guards and dry-run.
# Hermetic: no npm install, gh repo create, or live hook smoke. Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BOOTSTRAP="$ROOT/plugins/team-harness/scripts/interview-repo-bootstrap.sh"

WORKDIR=$(mktemp -d)
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

assert_dry_run_no_writes() {
  dir=$1
  before=$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
  sh "$BOOTSTRAP" --dry-run --dir "$dir"
  after=$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
  if [ "$before" != "$after" ]; then
    echo "error: dry-run wrote to $dir (before=$before after=$after)" >&2
    exit 1
  fi
}

# Default dry-run (current directory).
sh "$BOOTSTRAP" --dry-run

# Dry-run against a path that does not exist yet — must succeed without creating it.
MISSING="$WORKDIR/missing-target"
[ ! -e "$MISSING" ]
assert_dry_run_no_writes "$MISSING"
[ ! -e "$MISSING" ] || {
  echo "error: dry-run created missing target directory: $MISSING" >&2
  exit 1
}

# Non-empty directory guard — any entry (including hidden) must refuse and list paths.
NONEMPTY="$WORKDIR/nonempty"
mkdir -p "$NONEMPTY"
printf '' >"$NONEMPTY/.DS_Store"
if out=$(sh "$BOOTSTRAP" --dir "$NONEMPTY" 2>&1); then
  echo "error: expected non-empty guard to fail" >&2
  exit 1
fi
case "$out" in
  *"not empty"*) ;;
  *)
    echo "error: non-empty guard output missing 'not empty':" >&2
    printf '%s\n' "$out" >&2
    exit 1
    ;;
esac
case "$out" in
  *".DS_Store"*) ;;
  *)
    echo "error: non-empty guard output missing offending path .DS_Store:" >&2
    printf '%s\n' "$out" >&2
    exit 1
    ;;
esac

# --dir pointing at a file must fail clearly before bootstrap writes.
NOT_A_DIR="$WORKDIR/not-a-dir"
printf 'file\n' >"$NOT_A_DIR"
if out=$(sh "$BOOTSTRAP" --dir "$NOT_A_DIR" 2>&1); then
  echo "error: expected file target to fail" >&2
  exit 1
fi
case "$out" in
  *"not a directory"*) ;;
  *)
    echo "error: file target output missing 'not a directory':" >&2
    printf '%s\n' "$out" >&2
    exit 1
    ;;
esac

echo "ok interview-repo-bootstrap runtime (dry-run, missing-path dry-run, non-empty guard, file target)"
