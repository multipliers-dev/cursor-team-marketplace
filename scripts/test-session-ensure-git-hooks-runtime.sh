#!/usr/bin/env sh
# Runtime smoke: sessionStart verifies runnable hooks, repairs shims when possible, warns when not.
# Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SESSION="$ROOT/plugins/team-harness/scripts/session-ensure-git-hooks.sh"
PREPARE="$ROOT/plugins/team-harness/scripts/prepare-git-hooks.sh"
VERIFY="$ROOT/plugins/team-harness/scripts/verify-git-hooks.sh"
REPAIR="$ROOT/plugins/team-harness/scripts/husky-shim-repair.sh"
WARN_SENTINEL='HOOKS NOT RUNNABLE'

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
MAIN="$WORKDIR/main"
WT="$WORKDIR/wt"
AGENT_HOOKS_BACKUP=""
cleanup() {
  if [ -n "$AGENT_HOOKS_BACKUP" ] && [ -d "${AGENT_HOOKS_BACKUP}.session-test-bak" ]; then
    rm -rf "$AGENT_HOOKS_BACKUP"
    mv "${AGENT_HOOKS_BACKUP}.session-test-bak" "$AGENT_HOOKS_BACKUP"
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

AGENT_HOOKS_BACKUP="${HOME}/.cursor/agent-hooks"
if [ -d "$AGENT_HOOKS_BACKUP" ]; then
  mv "$AGENT_HOOKS_BACKUP" "${AGENT_HOOKS_BACKUP}.session-test-bak"
fi
unset CURSOR_AGENT_SOCKET

mkdir -p "$MAIN/scripts"
cd "$MAIN"
git init -b main
git config user.email "session-hooks-test@localhost"
git config user.name "Session Hooks Test"

cp "$PREPARE" "$VERIFY" "$REPAIR" "$MAIN/scripts/"
cat > "$MAIN/scripts/ensure-hooks.sh" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "$MAIN/scripts/"*.sh

node - "$PREPARE" "$VERIFY" <<'NODE'
const fs = require('fs');
const prepare = process.argv[2];
const verify = process.argv[3];
fs.writeFileSync(
  'package.json',
  `${JSON.stringify(
    {
      name: 'session-hooks-test',
      private: true,
      scripts: {
        prepare: `sh ${prepare}`,
        'verify:git-hooks': `sh ${verify}`,
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

unset CI VERCEL GITHUB_ACTIONS HUSKY
npm install --silent
export PATH="$MAIN/node_modules/.bin:$PATH"

cat > .husky/pre-commit <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x .husky/pre-commit

sh "$PREPARE"

printf 'init\n' > README.md
git add .
git commit -m "init"

COMMIT=$(git rev-parse HEAD)
git worktree add --detach "$WT" "$COMMIT"

cd "$WT"
export PATH="$MAIN/node_modules/.bin:$PATH"
cp -R "$MAIN/scripts" "$WT/scripts"
rm -rf .husky/_
git config core.hooksPath .husky/_

if sh "$VERIFY" >/dev/null 2>&1; then
  echo "error: verify should fail when worktree shims are missing" >&2
  exit 1
fi

session_err=$(mktemp)
if ! sh "$SESSION" 2>"$session_err"; then
  echo "error: session-ensure-git-hooks.sh must fail open (exit 0)" >&2
  cat "$session_err" >&2
  exit 1
fi

if grep -Fq "$WARN_SENTINEL" "$session_err"; then
  echo "error: session should repair shims, not warn, when husky is available" >&2
  cat "$session_err" >&2
  exit 1
fi

if ! sh "$VERIFY" >/dev/null 2>&1; then
  echo "error: verify should pass after sessionStart repair" >&2
  cat "$session_err" >&2
  exit 1
fi

# Broken repair path: fake husky that does not create shims → visible warning, still fail-open.
BROKEN="$WORKDIR/broken-repair"
FAKE_BIN="$WORKDIR/fake-bin"
mkdir -p "$BROKEN/scripts" "$FAKE_BIN"

cat > "$FAKE_BIN/husky" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "$FAKE_BIN/husky"

cd "$BROKEN"
git init -b main >/dev/null
git config user.email "session-hooks-test@localhost"
git config user.name "Session Hooks Test"
cp -R "$MAIN/node_modules" "$BROKEN/node_modules"
cp "$MAIN/package.json" "$BROKEN/package.json"
cp "$PREPARE" "$VERIFY" "$REPAIR" "$BROKEN/scripts/"
cat > "$BROKEN/scripts/ensure-hooks.sh" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "$BROKEN/scripts/"*.sh

mkdir -p .husky
cat > .husky/pre-commit <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x .husky/pre-commit
git config core.hooksPath .husky/_

unset CI VERCEL GITHUB_ACTIONS HUSKY
export PATH="$FAKE_BIN:$BROKEN/node_modules/.bin:$PATH"

warn_err=$(mktemp)
if ! sh "$SESSION" 2>"$warn_err"; then
  echo "error: session must fail open even when repair cannot fix shims" >&2
  cat "$warn_err" >&2
  exit 1
fi

if ! grep -Fq "$WARN_SENTINEL" "$warn_err"; then
  echo "error: session should emit HOOKS NOT RUNNABLE when shims stay broken" >&2
  cat "$warn_err" >&2
  exit 1
fi

echo "ok session-ensure-git-hooks runtime (repair on broken worktree, warn when repair fails, fail-open)"
