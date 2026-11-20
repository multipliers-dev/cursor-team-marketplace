#!/usr/bin/env sh
# Ensure committed vendor/savepoints-lite matches the pinned npm release (byte-identical skills).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PKG_ROOT="$ROOT/node_modules/@multipliers-dev/savepoints-lite"
VENDOR_ROOT="$ROOT/plugins/team-harness/vendor/savepoints-lite"
EXPECTED="$ROOT/scripts/expected-savepoints-vendor-paths.txt"

if [ ! -d "$PKG_ROOT/skills" ]; then
  echo "verify-savepoints-vendor: missing $PKG_ROOT/skills — run npm ci first" >&2
  exit 1
fi

PINNED="$(node -p "require('./package.json').devDependencies['@multipliers-dev/savepoints-lite']")"
INSTALLED="$(node -p "require('$PKG_ROOT/package.json').version")"
if [ "$PINNED" != "$INSTALLED" ]; then
  echo "verify-savepoints-vendor: pin $PINNED != installed $INSTALLED" >&2
  exit 1
fi

if [ ! -f "$VENDOR_ROOT/PACKAGE_VERSION" ]; then
  echo "verify-savepoints-vendor: missing $VENDOR_ROOT/PACKAGE_VERSION — run npm run sync:savepoints-vendor" >&2
  exit 1
fi

VENDOR_VER="$(tr -d '[:space:]' < "$VENDOR_ROOT/PACKAGE_VERSION")"
if [ "$VENDOR_VER" != "$INSTALLED" ]; then
  echo "verify-savepoints-vendor: vendor PACKAGE_VERSION $VENDOR_VER != npm $INSTALLED" >&2
  exit 1
fi

list_skills_files() {
  find "$1/skills" -type f | sed "s|^$1/||" | LC_ALL=C sort
}

NPM_FILES="$(list_skills_files "$PKG_ROOT")"
VENDOR_FILES="$(list_skills_files "$VENDOR_ROOT")"
if [ "$NPM_FILES" != "$VENDOR_FILES" ]; then
  echo "verify-savepoints-vendor: skills/ file inventory mismatch (npm vs vendor)" >&2
  inv_a="$(mktemp)"
  inv_b="$(mktemp)"
  printf '%s\n' "$NPM_FILES" > "$inv_a"
  printf '%s\n' "$VENDOR_FILES" > "$inv_b"
  comm -3 "$inv_a" "$inv_b" | sed 's/^/  /' >&2
  rm -f "$inv_a" "$inv_b"
  exit 1
fi

while IFS= read -r rel || [ -n "$rel" ]; do
  [ -z "$rel" ] && continue
  if [ ! -f "$PKG_ROOT/$rel" ]; then
    echo "verify-savepoints-vendor: manifest path missing in npm package: $rel" >&2
    exit 1
  fi
  if [ ! -f "$VENDOR_ROOT/$rel" ]; then
    echo "verify-savepoints-vendor: manifest path missing in vendor: $rel" >&2
    exit 1
  fi
done < "$EXPECTED"

CLI_REL="skills/bin/savepoints-lite-validate.mjs"
CLI_VENDOR="$VENDOR_ROOT/$CLI_REL"
if [ ! -f "$CLI_VENDOR" ]; then
  echo "verify-savepoints-vendor: missing vendored CLI $CLI_REL" >&2
  exit 1
fi
CLI_HEAD="$(head -n 1 "$CLI_VENDOR")"
if [ "$CLI_HEAD" != "#!/usr/bin/env node" ]; then
  echo "verify-savepoints-vendor: vendored CLI shebang must be '#!/usr/bin/env node' (got: $CLI_HEAD)" >&2
  exit 1
fi
if [ ! -x "$CLI_VENDOR" ]; then
  echo "verify-savepoints-vendor: vendored CLI must be executable: $CLI_REL" >&2
  exit 1
fi

# Post-sync upstream contract: integration-tier validation.post_write remains highest precedence.
VENDOR_ROUTER="$VENDOR_ROOT/skills/savepoints/SKILL.md"
VENDOR_PROVIDER="$VENDOR_ROOT/skills/savepoints-notion/SKILL.md"
if ! grep -q '### `validation.post_write`' "$VENDOR_ROUTER"; then
  echo "verify-savepoints-vendor: vendored router missing ### validation.post_write section" >&2
  exit 1
fi
if ! grep -q 'integration instruction/delegation context' "$VENDOR_ROUTER"; then
  echo "verify-savepoints-vendor: vendored router missing integration-tier validation.post_write precedence" >&2
  exit 1
fi
if ! grep -q 'post_write: false' "$VENDOR_ROOT/skills/savepoints/defaults.yml"; then
  echo "verify-savepoints-vendor: packaged defaults must keep validation.post_write: false" >&2
  exit 1
fi
if ! grep -q 'validation.post_write' "$VENDOR_PROVIDER"; then
  echo "verify-savepoints-vendor: vendored Notion provider missing validation.post_write consumption" >&2
  exit 1
fi
if ! grep -q 'router handoff' "$VENDOR_PROVIDER"; then
  echo "verify-savepoints-vendor: vendored Notion provider missing router handoff for validation.post_write" >&2
  exit 1
fi

while IFS= read -r rel || [ -n "$rel" ]; do
  [ -z "$rel" ] && continue
  src="$PKG_ROOT/$rel"
  dst="$VENDOR_ROOT/$rel"
  if ! cmp -s "$src" "$dst"; then
    echo "verify-savepoints-vendor: drift at $rel (vendor ≠ pinned npm) — run npm run sync:savepoints-vendor" >&2
    exit 1
  fi
done <<EOF
$NPM_FILES
EOF

FILE_COUNT="$(printf '%s\n' "$NPM_FILES" | grep -c . || true)"
MANIFEST_COUNT="$(grep -cve '^[[:space:]]*$' "$EXPECTED" || true)"
echo "verify-savepoints-vendor: ok ($INSTALLED, $FILE_COUNT skills files byte-checked, manifest $MANIFEST_COUNT paths, CLI shebang/executable + validation.post_write contract)"
