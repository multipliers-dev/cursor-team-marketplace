#!/usr/bin/env sh
# Runtime smoke: agent-hooks appearing after prepare must not silently skip Husky.
# Simulates Cloud VM ordering (prepare → late agent-hooks → start wait → commit).
# Invoked from scripts/check.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENSURE="$ROOT/plugins/team-harness/scripts/ensure-hooks.sh"
PREPARE="$ROOT/plugins/team-harness/scripts/prepare-git-hooks.sh"
VERIFY="$ROOT/plugins/team-harness/scripts/verify-git-hooks.sh"
REPAIR="$ROOT/plugins/team-harness/scripts/husky-shim-repair.sh"
START="$ROOT/plugins/team-harness/scripts/cloud-agent-start.sh"

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
MARKER="$WORKDIR/.hook-ran"
AGENT_HOOKS_ROOT="${HOME}/.cursor/agent-hooks"
AGENT_HOOKS_DIR="$AGENT_HOOKS_ROOT/timing-test"
AGENT_HOOKS_BACKUP=""
cleanup() {
  if [ -n "$AGENT_HOOKS_BACKUP" ] && [ -d "${AGENT_HOOKS_BACKUP}.timing-test-bak" ]; then
    rm -rf "$AGENT_HOOKS_BACKUP"
    mv "${AGENT_HOOKS_BACKUP}.timing-test-bak" "$AGENT_HOOKS_BACKUP"
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

if [ -d "$AGENT_HOOKS_ROOT" ]; then
  AGENT_HOOKS_BACKUP="$AGENT_HOOKS_ROOT"
  mv "$AGENT_HOOKS_ROOT" "${AGENT_HOOKS_ROOT}.timing-test-bak"
fi
rm -rf "$AGENT_HOOKS_ROOT"
mkdir -p "$MAIN/scripts"

install_fake_dispatcher() {
  mkdir -p "$AGENT_HOOKS_DIR"
  cat >"$AGENT_HOOKS_DIR/.dispatcher" <<'EOF'
#!/usr/bin/env sh
hook=$(basename "$0")
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
orig=$(cat "$dir/.cursor-original-hooks-path" 2>/dev/null || true)
if [ -n "$orig" ] && [ -x "$orig/$hook" ]; then
  exec "$orig/$hook"
fi
exit 0
EOF
  chmod +x "$AGENT_HOOKS_DIR/.dispatcher"
}

cd "$MAIN"
git init -b main
git config user.email "ensure-hooks-timing-test@localhost"
git config user.name "Ensure Hooks Timing Test"

cp "$ENSURE" "$PREPARE" "$VERIFY" "$REPAIR" "$START" "$MAIN/scripts/"
chmod +x "$MAIN/scripts/"*.sh

node - "$PREPARE" "$VERIFY" <<'NODE'
const fs = require('fs');
const prepare = process.argv[2];
const verify = process.argv[3];
fs.writeFileSync(
  'package.json',
  `${JSON.stringify(
    {
      name: 'ensure-hooks-timing-test',
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

export CURSOR_AGENT_SOCKET="$WORKDIR/fake.sock"
unset CI VERCEL GITHUB_ACTIONS HUSKY

npm install --silent
export PATH="$MAIN/node_modules/.bin:$PATH"

cat > .husky/pre-commit <<EOF
#!/usr/bin/env sh
touch "$MARKER"
EOF
chmod +x .husky/pre-commit

# prepare while agent-hooks is absent — must not fail install.
sh "$PREPARE"

# Cursor later installs agent-hooks and overwrites core.hooksPath without the bridge.
install_fake_dispatcher
git config core.hooksPath "$AGENT_HOOKS_DIR"

# best-effort after late install configures bridge immediately when present.
ENSURE_HOOKS_MODE=best-effort sh "$ENSURE"

bridge_file="$AGENT_HOOKS_DIR/.cursor-original-hooks-path"
if [ ! -f "$bridge_file" ] || [ "$(cat "$bridge_file")" != "${HOME}/.cursor/husky-bridge" ]; then
  echo "error: best-effort ensure-hooks should configure bridge once agent-hooks exists" >&2
  exit 1
fi

rm -f "$MARKER"
printf 'probe\n' > README.md
git add README.md
git commit -m "probe without bridge wait"

if [ ! -f "$MARKER" ]; then
  echo "error: pre-commit should run through agent-hooks bridge" >&2
  exit 1
fi

# require mode fails closed when Cloud agent-hooks dir exists but dispatcher is not installed yet.
rm -rf "$AGENT_HOOKS_ROOT"
mkdir -p "$AGENT_HOOKS_ROOT"
git config --unset core.hooksPath 2>/dev/null || true
git config core.hooksPath .husky/_

if ENSURE_HOOKS_MODE=require sh "$ENSURE" >/dev/null 2>&1; then
  echo "error: require mode should fail when agent-hooks is missing on Cloud" >&2
  exit 1
fi

# Broken bridge metadata is repaired (not silently skipped).
install_fake_dispatcher
git config core.hooksPath "$AGENT_HOOKS_DIR"
echo "broken-bridge" >"$bridge_file"
rm -f "$AGENT_HOOKS_DIR/pre-commit"

ENSURE_HOOKS_MODE=require sh "$ENSURE"

if [ "$(cat "$bridge_file")" != "${HOME}/.cursor/husky-bridge" ]; then
  echo "error: require mode should repair broken bridge metadata" >&2
  exit 1
fi

# wait mode with delayed agent-hooks (background) — cloud-agent-start contract.
rm -rf "$AGENT_HOOKS_ROOT"
mkdir -p "$AGENT_HOOKS_ROOT"
git config core.hooksPath .husky/_

(
  sleep 2
  install_fake_dispatcher
) &
delayed_pid=$!

export ENSURE_HOOKS_MODE=wait
export ENSURE_HOOKS_WAIT_SECS=10
export ENSURE_HOOKS_START_WAIT_SECS=10

if ! sh "$START"; then
  wait "$delayed_pid" 2>/dev/null || true
  echo "error: cloud-agent-start should succeed once agent-hooks appears" >&2
  exit 1
fi
wait "$delayed_pid" 2>/dev/null || true

if [ "$(cat "$bridge_file")" != "${HOME}/.cursor/husky-bridge" ]; then
  echo "error: cloud-agent-start wait mode should restore bridge" >&2
  exit 1
fi

echo "ok ensure-hooks agent-hooks timing (late install, require fail-closed, start wait)"
