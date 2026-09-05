#!/usr/bin/env python3
"""Small structural checks; not a substitute for code or artistic review."""
from __future__ import annotations
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {".git", ".godot", ".tools", ".cache", "artifacts", "build", "vendor", "__pycache__"}
RESOURCE_PATTERN = re.compile(r'res://[^\s"\)]+')
DOMAIN_FORBIDDEN = re.compile(r'extends\s+(?:Node|Node3D|CharacterBody3D)|\b(?:Time|Input|OS|RenderingServer|AudioServer)\.|get_tree\(')


def main() -> None:
    errors: list[str] = []
    classes: dict[str, str] = {}
    for path in ROOT.rglob("*"):
        relative = path.relative_to(ROOT)
        if not path.is_file() or any(part in EXCLUDED for part in relative.parts):
            continue
        if path.suffix not in {".gd", ".tscn", ".tres"}:
            continue
        text = path.read_text(encoding="utf-8")
        if path.suffix == ".gd":
            for name in re.findall(r'^class_name\s+(\w+)', text, re.M):
                if name in classes:
                    errors.append(f"Duplicate class {name}: {relative} / {classes[name]}")
                classes[name] = str(relative)
            if "domain" in relative.parts and DOMAIN_FORBIDDEN.search(text):
                errors.append(f"Engine dependency in domain: {relative}")
        for reference in RESOURCE_PATTERN.findall(text):
            if not (ROOT / reference.removeprefix("res://")).exists():
                errors.append(f"Missing resource {reference} in {relative}")
    if len((ROOT / "AGENTS.md").read_text().split()) > 800:
        errors.append("Root AGENTS.md exceeded its 800-word ceiling")
    manifest = json.loads((ROOT / "assets/manifest.json").read_text())
    for pack in manifest["packs"]:
        if not pack.get("license") or not re.fullmatch(r'[a-f0-9]{64}', pack.get("sha256", "")):
            errors.append(f"Unpinned asset provenance: {pack.get('id')}")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"GUESTS_STRUCTURE_OK classes={len(classes)}")


if __name__ == "__main__":
    main()
