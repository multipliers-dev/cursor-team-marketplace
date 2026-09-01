#!/usr/bin/env sh
# Portable afterFileEdit formatter (team-harness marketplace primitive).
# Fail-open Prettier on agent-edited files; path-safe; rechains ensure-hooks.
# Optional Layer 2a — agent ergonomics / redundant formatting only.
# NOT a substitute for Husky, pre-commit lint/typecheck, or CI format:check.
# Copy to .cursor/hooks/format.sh and wire afterFileEdit in hooks.json.

trap 'exit 0' EXIT

command -v git >/dev/null 2>&1 || exit 0
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

ensure="$repo_root/scripts/ensure-hooks.sh"
[ -f "$ensure" ] && sh "$ensure" >/dev/null 2>&1 || true

file_path=${1:-}
[ -n "$file_path" ] || exit 0

case "$file_path" in
  /*) candidate="$file_path" ;;
  *) candidate="$repo_root/$file_path" ;;
esac

dir_part=$(dirname "$candidate")
base_part=$(basename "$candidate")
if ! dir_part=$(CDPATH= cd "$dir_part" 2>/dev/null && pwd); then
  exit 0
fi
abs_path="$dir_part/$base_part"

case "$abs_path" in
  "$repo_root"/*) ;;
  *) exit 0 ;;
esac

[ -f "$abs_path" ] || exit 0

case "$abs_path" in
  *.md | *.json | *.yaml | *.yml | *.css | *.scss | *.html \
  | *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs) ;;
  *) exit 0 ;;
esac

if command -v npx >/dev/null 2>&1; then
  npx --no-install prettier --write "$abs_path" >/dev/null 2>&1 || true
elif command -v prettier >/dev/null 2>&1; then
  prettier --write "$abs_path" >/dev/null 2>&1 || true
fi
