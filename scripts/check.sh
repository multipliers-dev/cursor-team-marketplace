#!/usr/bin/env sh
# Structural CI for the marketplace plugin (JSON, skill frontmatter, script syntax).
set -eu
cd "$(dirname "$0")/.."

python3 - <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(".").resolve()


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        die(f"{path}: {exc}")
    raise AssertionError


def parse_frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text()
    if not text.startswith("---\n"):
        die(f"{path}: missing YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end == -1:
        die(f"{path}: unclosed YAML frontmatter")
    data: dict[str, str] = {}
    key: str | None = None
    chunks: list[str] = []
    for line in text[4:end].splitlines():
        if key and (line.startswith("  ") or line.startswith("\t")):
            chunks.append(line.strip())
            continue
        if ":" in line and not line.startswith((" ", "\t")):
            if key:
                data[key] = " ".join(chunks).strip()
            key, _, rest = line.partition(":")
            key = key.strip()
            rest = rest.strip().lstrip(">-").strip()
            chunks = [rest] if rest else []
            continue
        if key and line.strip():
            chunks.append(line.strip())
    if key:
        data[key] = " ".join(chunks).strip()
    return data


marketplace_path = ROOT / ".cursor-plugin" / "marketplace.json"
marketplace = load_json(marketplace_path)
if not isinstance(marketplace, dict):
    die("marketplace.json: expected object")
metadata = marketplace.get("metadata") or {}
plugin_root = ROOT / str(metadata.get("pluginRoot", "plugins"))
plugins = marketplace.get("plugins")
if not isinstance(plugins, list) or not plugins:
    die("marketplace.json: plugins must be a non-empty list")

for plugin in plugins:
    if not isinstance(plugin, dict):
        die("marketplace.json: plugin entries must be objects")
    source = plugin.get("source")
    if not source:
        die("marketplace.json: plugin missing source")
    plugin_dir = plugin_root / str(source)
    if not plugin_dir.is_dir():
        die(f"missing plugin dir: {plugin_dir}")
    plugin_json_path = plugin_dir / ".cursor-plugin" / "plugin.json"
    plugin_json = load_json(plugin_json_path)
    if not isinstance(plugin_json, dict) or not plugin_json.get("name"):
        die(f"{plugin_json_path}: missing name")
    print(f"ok plugin {plugin_json['name']}")

    skills_dir = plugin_dir / "skills"
    skill_mds = sorted(skills_dir.glob("*/SKILL.md")) if skills_dir.is_dir() else []
    if not skill_mds:
        die(f"{skills_dir}: no SKILL.md files")
    for skill_md in skill_mds:
        fm = parse_frontmatter(skill_md)
        expected = skill_md.parent.name
        if fm.get("name") != expected:
            die(f"{skill_md}: frontmatter name {fm.get('name')!r} != {expected!r}")
        if not fm.get("description"):
            die(f"{skill_md}: missing description")
        print(f"ok skill {expected}")

    interview_script = plugin_dir / "scripts" / "interview-repo-bootstrap.sh"
    if not interview_script.is_file():
        die(f"missing script: {interview_script}")
    print(f"ok script {interview_script.relative_to(ROOT)}")

    template_dir = plugin_dir / "templates" / "interview-repo"
    required_templates = [
        ".gitignore",
        "AGENTS.md",
        "README.md",
        "package.json",
        "tsconfig.json",
        "src/index.ts",
        ".husky/pre-commit",
        ".cursor/hooks.json",
        ".cursor/environment.json",
        ".github/workflows/ci.yml",
    ]
    for rel in required_templates:
        path = template_dir / rel
        if not path.is_file():
            die(f"missing template: {path}")
    print(f"ok templates interview-repo ({len(required_templates)} files)")

print("ok marketplace plugin")
PY

for script in plugins/team-harness/scripts/*.sh; do
  sh -n "$script"
  echo "ok script $script"
done

sh scripts/test-cloud-agent-install-runtime.sh
sh scripts/test-interview-repo-bootstrap-runtime.sh
