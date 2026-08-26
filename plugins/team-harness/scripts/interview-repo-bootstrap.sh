#!/usr/bin/env sh
# Bootstrap an actually-empty directory into a pre-wired interview repo
# (TypeScript + Vitest + AGENTS.md + Husky + minimal CI + GitHub remote).
# Copies templates/interview-repo/ plus an explicit hook-primitive allowlist only.
set -eu

PLUGIN_ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
TEMPLATE_DIR="$PLUGIN_ROOT/templates/interview-repo"
SENTINEL='[interview-bootstrap] pre-commit verify'

REPO_NAME=""
TARGET_DIR=""
PUBLIC=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: interview-repo-bootstrap.sh [--name NAME] [--dir DIR] [--public] [--dry-run]

Bootstrap an empty directory into a pre-wired technical interview repo.

Options:
  --name NAME   GitHub repo name (default: basename of target directory)
  --dir DIR     Target directory (default: current working directory)
  --public      Create a public GitHub repo (default: private)
  --dry-run     Validate tooling only; no writes or gh auth
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

log() {
  echo "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --name)
        [ $# -ge 2 ] || die "--name requires a value"
        REPO_NAME=$2
        shift 2
        ;;
      --dir)
        [ $# -ge 2 ] || die "--dir requires a value"
        TARGET_DIR=$2
        shift 2
        ;;
      --public)
        PUBLIC=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1 (try --help)"
        ;;
    esac
  done
}

resolve_paths() {
  if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR=$PWD
  elif [ -e "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR" ]; then
    die "target path is not a directory: $TARGET_DIR"
  elif [ -d "$TARGET_DIR" ]; then
    TARGET_DIR=$(CDPATH= cd "$TARGET_DIR" && pwd)
  elif [ "$DRY_RUN" -eq 1 ]; then
    : # missing path is ok for dry-run summary; no writes
  else
    mkdir -p "$TARGET_DIR"
    TARGET_DIR=$(CDPATH= cd "$TARGET_DIR" && pwd)
  fi

  if [ -z "$REPO_NAME" ]; then
    REPO_NAME=$(basename "$TARGET_DIR")
  fi
}

check_tooling() {
  require_cmd sh
  require_cmd git
  require_cmd node
  require_cmd npm
  if [ "$DRY_RUN" -eq 0 ]; then
    require_cmd gh
  fi
  [ -d "$TEMPLATE_DIR" ] || die "missing template directory: $TEMPLATE_DIR"
  for script in prepare-git-hooks.sh ensure-hooks.sh session-ensure-git-hooks.sh; do
    [ -f "$PLUGIN_ROOT/scripts/$script" ] || die "missing hook primitive: $PLUGIN_ROOT/scripts/$script"
  done
}

guard_not_inside_parent_worktree() {
  [ -d "$TARGET_DIR" ] || return 0
  parent=$TARGET_DIR
  while [ "$parent" != "/" ]; do
    parent=$(dirname "$parent")
    if git -C "$parent" rev-parse --git-dir >/dev/null 2>&1; then
      die "target directory is inside an existing git worktree: $parent"
    fi
  done
}

guard_empty_directory() {
  [ -d "$TARGET_DIR" ] || return 0
  if [ -d "$TARGET_DIR/.git" ]; then
    die "refusing to bootstrap: $TARGET_DIR already contains .git/"
  fi

  # shellcheck disable=SC2012
  entries=$(ls -A "$TARGET_DIR" 2>/dev/null || true)
  if [ -n "$entries" ]; then
    echo "error: target directory is not empty ($TARGET_DIR):" >&2
    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -print | sort >&2
    die "remove entries or choose another directory with --dir"
  fi
}

substitute_repo_name() {
  repo=$1
  for file in README.md package.json .cursor/environment.json; do
    target="$TARGET_DIR/$file"
    if [ -f "$target" ]; then
      sed "s/__REPO_NAME__/$repo/g" "$target" >"$target.tmp"
      mv "$target.tmp" "$target"
    fi
  done
}

copy_template_tree() {
  # Copy preset including dotfiles; .gitignore lands before npm install.
  cp -a "$TEMPLATE_DIR/." "$TARGET_DIR/"
}

copy_hook_primitives() {
  mkdir -p "$TARGET_DIR/scripts" "$TARGET_DIR/.cursor/hooks"
  cp "$PLUGIN_ROOT/scripts/prepare-git-hooks.sh" "$TARGET_DIR/scripts/prepare-git-hooks.sh"
  cp "$PLUGIN_ROOT/scripts/ensure-hooks.sh" "$TARGET_DIR/scripts/ensure-hooks.sh"
  cp "$PLUGIN_ROOT/scripts/session-ensure-git-hooks.sh" "$TARGET_DIR/.cursor/hooks/ensure-git-hooks.sh"
  chmod +x "$TARGET_DIR/scripts/prepare-git-hooks.sh" \
    "$TARGET_DIR/scripts/ensure-hooks.sh" \
    "$TARGET_DIR/.cursor/hooks/ensure-git-hooks.sh" \
    "$TARGET_DIR/.husky/pre-commit"
}

maybe_rewrite_environment_install() {
  env_file="$TARGET_DIR/.cursor/environment.json"
  if [ -f "$TARGET_DIR/package-lock.json" ]; then
    node - "$env_file" <<'NODE'
const fs = require('fs');
const path = process.argv[2];
const env = JSON.parse(fs.readFileSync(path, 'utf8'));
env.install = 'npm ci';
fs.writeFileSync(path, JSON.stringify(env, null, 2) + '\n');
NODE
  fi
}

run_hook_smoke() {
  log "Running direct pre-commit smoke..."
  direct_out=$(cd "$TARGET_DIR" && sh .husky/pre-commit 2>&1) || die "direct pre-commit hook failed"
  printf '%s\n' "$direct_out"
  echo "$direct_out" | grep -Fq "$SENTINEL" || die "direct pre-commit output missing sentinel: $SENTINEL"
}

run_git_commit_smoke() {
  log "Running git commit hook smoke..."
  (
    cd "$TARGET_DIR"
    git add .
    commit_out=$(git -c user.name="Interview Bootstrap" -c user.email="bootstrap@localhost" \
      commit -m "Initial commit" 2>&1) || die "initial git commit failed"
    printf '%s\n' "$commit_out"
    echo "$commit_out" | grep -Fq "$SENTINEL" || die "git commit output missing sentinel — hook bypassed or miswired"
  )
}

create_github_remote() {
  visibility_flag=--private
  if [ "$PUBLIC" -eq 1 ]; then
    visibility_flag=--public
  fi

  log "Creating GitHub repo and pushing..."
  (
    cd "$TARGET_DIR"
    # shellcheck disable=SC2086
    gh repo create "$REPO_NAME" \
      --source=. \
      --remote=origin \
      --push \
      $visibility_flag
  )
}

print_repo_urls() {
  (
    cd "$TARGET_DIR"
    if url=$(gh repo view --json url -q .url 2>/dev/null); then
      log "Repository: $url"
    fi
  )
}

dry_run_summary() {
  visibility=private
  if [ "$PUBLIC" -eq 1 ]; then
    visibility=public
  fi
  log "[dry-run] target directory: $TARGET_DIR"
  log "[dry-run] repo name: $REPO_NAME"
  log "[dry-run] visibility: $visibility"
  log "[dry-run] would copy template from: $TEMPLATE_DIR"
  log "[dry-run] would copy hook primitives: prepare-git-hooks.sh, ensure-hooks.sh, session-ensure-git-hooks.sh"
  log "[dry-run] would run: git init -b main"
  log "[dry-run] would run: npm install"
  log "[dry-run] would run hook smoke and git commit with sentinel assertion"
  log "[dry-run] would run: gh repo create \"$REPO_NAME\" --source=. --remote=origin --push --$visibility"
  log "[dry-run] ok — tooling present; no writes performed"
}

main() {
  parse_args "$@"
  resolve_paths
  check_tooling
  if [ "$DRY_RUN" -eq 0 ]; then
    guard_not_inside_parent_worktree
    guard_empty_directory
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    dry_run_summary
    exit 0
  fi

  log "Bootstrapping interview repo in $TARGET_DIR (name: $REPO_NAME)..."

  copy_template_tree
  substitute_repo_name "$REPO_NAME"
  copy_hook_primitives

  (
    cd "$TARGET_DIR"
    git init -b main
    npm install
  )

  maybe_rewrite_environment_install
  run_hook_smoke
  run_git_commit_smoke
  create_github_remote
  print_repo_urls

  log "Interview repo bootstrap complete."
}

main "$@"
