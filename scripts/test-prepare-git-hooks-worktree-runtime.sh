#!/usr/bin/env sh
# Runtime smoke: fresh-worktree-shaped Husky state must run pre-commit on commit.
# Reproduces core.hooksPath=.husky/_ with .husky/_ missing; prepare must repair shims
# and a throwaway commit must execute the hook (marker + sentinel), not merely create shims.
# Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PREPARE="$ROOT/plugins/team-harness/scripts/prepare-git-hooks.sh"
VERIFY="$ROOT/plugins/team-harness/scripts/verify-git-hooks.sh"
SENTINEL='[worktree-hooks-test] pre-commit executed'

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: missing required command: $1" >&2
    exit 1
  }
}

require_cmd git
require_cmd npm
require_cmd node

WORKDIR=$(mktemp -d)
MARKER="$WORKDIR/.hook-ran"
AGENT_HOOKS_BACKUP=""
cleanup() {
  if [ -n "$AGENT_HOOKS_BACKUP" ] && [ -d "${AGENT_HOOKS_BACKUP}.worktree-test-bak" ]; then
    rm -rf "$AGENT_HOOKS_BACKUP"
    mv "${AGENT_HOOKS_BACKUP}.worktree-test-bak" "$AGENT_HOOKS_BACKUP"
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

# Hermetic: avoid Cloud agent-hooks rewriting core.hooksPath during the probe.
AGENT_HOOKS_BACKUP="${HOME}/.cursor/agent-hooks"
if [ -d "$AGENT_HOOKS_BACKUP" ]; then
  mv "$AGENT_HOOKS_BACKUP" "${AGENT_HOOKS_BACKUP}.worktree-test-bak"
fi
unset CURSOR_AGENT_SOCKET

cd "$WORKDIR"
git init -b main
git config user.email "worktree-hooks-test@localhost"
git config user.name "Worktree Hooks Test"

node - "$PREPARE" <<'NODE'
const fs = require('fs');
const prepare = process.argv[2];
fs.writeFileSync(
  'package.json',
  `${JSON.stringify(
    {
      name: 'worktree-hooks-test',
      private: true,
      scripts: {
        prepare: `sh ${prepare}`,
      },
      devDependencies: {
        husky: '^9.1.7',
      },
    },
    null,
    2,
  )}\n`,
);
NODE

# Avoid CI skip paths during install/prepare; keep husky CLI on PATH.
unset CI VERCEL GITHUB_ACTIONS HUSKY

npm install --silent
export PATH="$WORKDIR/node_modules/.bin:$PATH"

cat > .husky/pre-commit <<EOF
#!/usr/bin/env sh
echo "$SENTINEL"
: > "$MARKER"
EOF
chmod +x .husky/pre-commit

sh "$PREPARE"

printf 'init\n' > README.md
git add .
git commit -m "init"

# Fresh-worktree-shaped broken state: hooksPath set, shim dir absent.
rm -rf .husky/_
git config core.hooksPath .husky/_

if sh "$VERIFY" >/dev/null 2>&1; then
  echo "error: verify-git-hooks.sh should fail when .husky/_ shims are missing" >&2
  exit 1
fi

sh "$PREPARE"

if [ ! -f .husky/_/pre-commit ]; then
  echo "error: prepare did not create .husky/_/pre-commit shim" >&2
  exit 1
fi

sh "$VERIFY"

rm -f "$MARKER"
commit_out=$(git commit --allow-empty -m "worktree hook probe" 2>&1) || {
  printf '%s\n' "$commit_out" >&2
  echo "error: throwaway commit failed after prepare repair" >&2
  exit 1
}

if [ ! -f "$MARKER" ]; then
  echo "error: pre-commit hook did not execute (marker file missing)" >&2
  printf '%s\n' "$commit_out" >&2
  exit 1
fi

case "$commit_out" in
  *"$SENTINEL"*) ;;
  *)
    echo "error: commit output missing sentinel — hook bypassed or miswired" >&2
    printf '%s\n' "$commit_out" >&2
    exit 1
    ;;
esac

echo "ok prepare-git-hooks worktree runtime (verify fail/repair, hook executed on commit)"
