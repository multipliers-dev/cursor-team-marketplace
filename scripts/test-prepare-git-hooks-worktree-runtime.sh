#!/usr/bin/env sh
# Runtime smoke: fresh-worktree-shaped Husky state must run pre-commit on commit.
# Proven acceptance from codenames #546, implemented as marketplace shell smoke (no vitest).
# Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PREPARE="$ROOT/plugins/team-harness/scripts/prepare-git-hooks.sh"
VERIFY="$ROOT/plugins/team-harness/scripts/verify-git-hooks.sh"

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

mkdir -p "$MAIN"
cd "$MAIN"
git init -b main
git config user.email "worktree-hooks-test@localhost"
git config user.name "Worktree Hooks Test"

node - "$PREPARE" "$VERIFY" <<'NODE'
const fs = require('fs');
const prepare = process.argv[2];
const verify = process.argv[3];
fs.writeFileSync(
  'package.json',
  `${JSON.stringify(
    {
      name: 'worktree-hooks-test',
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

cat > .husky/pre-push <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x .husky/pre-push

sh "$PREPARE"

printf 'init\n' > README.md
git add .
git commit -m "init"

COMMIT=$(git rev-parse HEAD)
git worktree add --detach "$WT" "$COMMIT"

cd "$WT"
export PATH="$MAIN/node_modules/.bin:$PATH"

rm -rf .husky/_
git config core.hooksPath .husky/_

if sh "$VERIFY" >/dev/null 2>&1; then
  echo "error: verify-git-hooks.sh should fail when .husky/_ shims are missing" >&2
  exit 1
fi

sh "$PREPARE"

if [ ! -x .husky/_/pre-commit ] || [ ! -x .husky/_/pre-push ]; then
  echo "error: prepare did not create executable shims for defined hooks" >&2
  exit 1
fi

sh "$VERIFY"

cat > .husky/pre-commit <<EOF
#!/usr/bin/env sh
touch "$MARKER"
EOF
chmod +x .husky/pre-commit

rm -f "$MARKER"
git add .husky/pre-commit
git commit -m "worktree hook probe"

if [ ! -f "$MARKER" ]; then
  echo "error: pre-commit hook did not execute (marker file missing)" >&2
  exit 1
fi

# Supporting: verify ignores hooks the repo does not define.
VERIFY_ONLY="$WORKDIR/verify-only"
mkdir -p "$VERIFY_ONLY/.husky"
cd "$VERIFY_ONLY"
git init -b main >/dev/null
git config user.email "worktree-hooks-test@localhost"
git config user.name "Worktree Hooks Test"
cp -R "$MAIN/node_modules" "$VERIFY_ONLY/node_modules"
cp "$MAIN/package.json" "$VERIFY_ONLY/package.json"

cat > .husky/pre-push <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x .husky/pre-push

export PATH="$VERIFY_ONLY/node_modules/.bin:$PATH"
sh "$PREPARE"

if [ ! -x .husky/_/pre-push ]; then
  echo "error: prepare did not create executable pre-push shim" >&2
  exit 1
fi

# Non-executable shim must fail verify even when the file exists.
chmod -x .husky/_/pre-push
if sh "$VERIFY" >/dev/null 2>&1; then
  echo "error: verify-git-hooks.sh should fail when shim exists but is not executable" >&2
  exit 1
fi

echo "ok prepare-git-hooks worktree runtime (verify fail/repair, hook executed on commit, generalized verify)"
