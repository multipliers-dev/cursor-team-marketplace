#!/usr/bin/env sh
# Runtime smoke test for repo-bootstrap.sh guards and dry-run.
# Hermetic: no npm install, gh repo create, or live hook smoke. Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BOOTSTRAP="$ROOT/plugins/team-harness/scripts/repo-bootstrap.sh"

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

assert_dir_unchanged() {
  dir=$1
  if [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]; then
    echo "error: bootstrap wrote to $dir despite expected failure" >&2
    find "$dir" -mindepth 1 -maxdepth 1 -print >&2
    exit 1
  fi
}

assert_invalid_repo_name() {
  name=$1
  dir=$2
  if out=$(sh "$BOOTSTRAP" --name "$name" --dir "$dir" 2>&1); then
    echo "error: expected invalid repo name to fail: $name" >&2
    exit 1
  fi
  case "$out" in
    *"invalid GitHub repo name"*) ;;
    *)
      echo "error: invalid repo name output missing clear error for $name:" >&2
      printf '%s\n' "$out" >&2
      exit 1
      ;;
  esac
  assert_dir_unchanged "$dir"
}

assert_invalid_owner() {
  owner=$1
  dir=$2
  if out=$(sh "$BOOTSTRAP" --owner "$owner" --name renovate-workflow --dir "$dir" 2>&1); then
    echo "error: expected invalid owner to fail: $owner" >&2
    exit 1
  fi
  case "$out" in
    *"invalid GitHub owner"*) ;;
    *)
      echo "error: invalid owner output missing clear error for $owner:" >&2
      printf '%s\n' "$out" >&2
      exit 1
      ;;
  esac
  assert_dir_unchanged "$dir"
}

assert_dry_run_create_target() {
  out=$1
  expected=$2
  case "$out" in
    *"[dry-run] create target: $expected"*) ;;
    *)
      echo "error: expected dry-run create target $expected:" >&2
      printf '%s\n' "$out" >&2
      exit 1
      ;;
  esac
  case "$out" in
    *"gh repo create \"$expected\""*) ;;
    *)
      echo "error: expected dry-run gh repo create \"$expected\":" >&2
      printf '%s\n' "$out" >&2
      exit 1
      ;;
  esac
}

extract_create_target() {
  printf '%s\n' "$1" | sed -n 's/^\[dry-run\] create target: //p' | head -n 1
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

# Invalid GitHub repo names must fail before any writes.
EMPTY="$WORKDIR/empty-name-check"
mkdir -p "$EMPTY"
assert_invalid_repo_name 'org/repo' "$EMPTY"
assert_invalid_repo_name 'bad&name' "$EMPTY"
if out=$(sh "$BOOTSTRAP" --dry-run --name 'org/repo' --dir "$EMPTY" 2>&1); then
  echo "error: expected dry-run with invalid repo name to fail" >&2
  exit 1
fi
case "$out" in
  *"invalid GitHub repo name"*) ;;
  *)
    echo "error: dry-run invalid repo name output missing clear error:" >&2
    printf '%s\n' "$out" >&2
    exit 1
    ;;
esac

# Literal substitution via the real bootstrap script (test-only stop before git/npm/gh).
SUBST="$WORKDIR/subst-check"
mkdir -p "$SUBST"
REPO_NAME='my.repo_name-test'
REPO_BOOTSTRAP_STOP_AFTER_SUBSTITUTE=1 sh "$BOOTSTRAP" --name "$REPO_NAME" --dir "$SUBST"
node - "$SUBST" "$REPO_NAME" <<'NODE'
const fs = require('fs');
const path = require('path');

const targetDir = process.argv[2];
const repo = process.argv[3];

const pkg = JSON.parse(fs.readFileSync(path.join(targetDir, 'package.json'), 'utf8'));
const env = JSON.parse(fs.readFileSync(path.join(targetDir, '.cursor/environment.json'), 'utf8'));
const readme = fs.readFileSync(path.join(targetDir, 'README.md'), 'utf8');

if (pkg.name !== repo || env.name !== repo || readme !== `# ${repo}\n`) {
  throw new Error('bootstrap substitution mismatch');
}
if (readme.includes('__REPO_NAME__') || JSON.stringify(pkg).includes('__REPO_NAME__')) {
  throw new Error('placeholder was not replaced');
}
NODE

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

# --owner constructs owner/name; --org is a true alias for the same create target.
OWNER_DIR="$WORKDIR/owner-flag"
mkdir -p "$OWNER_DIR"
owner_out=$(sh "$BOOTSTRAP" --dry-run --owner multipliers-dev --name renovate-workflow --dir "$OWNER_DIR")
org_out=$(sh "$BOOTSTRAP" --dry-run --org multipliers-dev --name renovate-workflow --dir "$OWNER_DIR")
assert_dry_run_create_target "$owner_out" "multipliers-dev/renovate-workflow"
assert_dry_run_create_target "$org_out" "multipliers-dev/renovate-workflow"
owner_target=$(extract_create_target "$owner_out")
org_target=$(extract_create_target "$org_out")
if [ "$owner_target" != "$org_target" ]; then
  echo "error: --org create target ($org_target) must equal --owner ($owner_target)" >&2
  exit 1
fi
if [ "$owner_target" != "multipliers-dev/renovate-workflow" ]; then
  echo "error: expected create target multipliers-dev/renovate-workflow, got $owner_target" >&2
  exit 1
fi
assert_dry_run_no_writes "$OWNER_DIR"

# Invalid owner fails before writes.
assert_invalid_owner 'org/name' "$OWNER_DIR"
assert_invalid_owner 'bad&owner' "$OWNER_DIR"
if out=$(sh "$BOOTSTRAP" --dry-run --owner 'org/name' --name renovate-workflow --dir "$OWNER_DIR" 2>&1); then
  echo "error: expected dry-run with invalid owner to fail" >&2
  exit 1
fi
case "$out" in
  *"invalid GitHub owner"*) ;;
  *)
    echo "error: dry-run invalid owner output missing clear error:" >&2
    printf '%s\n' "$out" >&2
    exit 1
    ;;
esac

# Omitted owner keeps authenticated-user create (no owner prefix).
omit_out=$(sh "$BOOTSTRAP" --dry-run --name renovate-workflow --dir "$OWNER_DIR")
assert_dry_run_create_target "$omit_out" "renovate-workflow"
case "$omit_out" in
  *"/renovate-workflow"*)
    echo "error: omitted owner must not prefix create target:" >&2
    printf '%s\n' "$omit_out" >&2
    exit 1
    ;;
esac

echo "ok repo-bootstrap runtime (dry-run, invalid repo names, owner/org create target, invalid owner, omitted owner, literal substitution, non-empty guard, file target)"
