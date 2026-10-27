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
  src="$PKG_ROOT/$rel"
  dst="$VENDOR_ROOT/$rel"
  if [ ! -f "$src" ]; then
    echo "verify-savepoints-vendor: npm package missing $rel" >&2
    exit 1
  fi
  if [ ! -f "$dst" ]; then
    echo "verify-savepoints-vendor: vendor missing $rel — run npm run sync:savepoints-vendor" >&2
    exit 1
  fi
  if ! cmp -s "$src" "$dst"; then
    echo "verify-savepoints-vendor: drift at $rel (vendor ≠ pinned npm) — run npm run sync:savepoints-vendor" >&2
    exit 1
  fi
done < "$EXPECTED"

FILE_COUNT="$(printf '%s\n' "$NPM_FILES" | grep -c . || true)"
echo "verify-savepoints-vendor: ok ($INSTALLED, $FILE_COUNT skills files, manifest $(wc -l < "$EXPECTED" | tr -d ' ') paths)"
