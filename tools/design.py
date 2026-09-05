#!/usr/bin/env python3
"""Validate and package design documents; never edits runtime game content."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlparse
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.2"
BASENAME = f"GUESTS-design-v{VERSION}"
CHAPTERS = [
    "docs/DESIGN.md",
    "docs/design/01-world-story.md",
    "docs/design/02-player-journey.md",
    "docs/design/03-loop-progression.md",
    "docs/design/04-gameplay-coop.md",
    "docs/design/05-case-001.md",
    "docs/design/06-bestiary.md",
    "docs/design/07-ui-ux.md",
    "docs/design/08-environment-art.md",
    "docs/design/09-audio.md",
    "docs/ARCHITECTURE.md",
    "docs/ASSETS.md",
    "docs/WORKFLOW.md",
    "docs/ROADMAP.md",
    "docs/SOURCES.md",
    "AGENTS.md",
]
LINK = re.compile(r"(!?\[[^\]]*\]\()([^\)]+)(\))")


def documents() -> list[Path]:
    return [ROOT / "AGENTS.md", *sorted((ROOT / "docs").rglob("*.md"))]


def check() -> dict[str, int]:
    errors: list[str] = []
    for name in CHAPTERS:
        if not (ROOT / name).is_file():
            errors.append(f"Required document missing: {name}")
    words = 0
    link_count = 0
    for path in documents():
        text = path.read_text(encoding="utf-8")
        words += len(text.split())
        if not text.startswith("# ") or not text.endswith("\n"):
            errors.append(f"Expected title and final newline: {path.relative_to(ROOT)}")
        for match in LINK.finditer(text):
            target = match.group(2).strip().split(' "', 1)[0]
            parsed = urlparse(target)
            if parsed.scheme or target.startswith("#"):
                continue
            local = (path.parent / unquote(parsed.path)).resolve()
            if not local.is_relative_to(ROOT) or not local.exists():
                errors.append(f"Broken local link: {path.relative_to(ROOT)} -> {target}")
            link_count += 1
    agents_words = len((ROOT / "AGENTS.md").read_text(encoding="utf-8").split())
    if agents_words > 800:
        errors.append(f"AGENTS exceeds 800 words: {agents_words}")
    tuning_path = ROOT / "docs/design/tuning.v0.2.json"
    tuning = json.loads(tuning_path.read_text(encoding="utf-8"))
    if tuning.get("status") != "proposal_not_runtime" or tuning.get("runtime_consumed") is not False:
        errors.append("Design tuning must remain an explicitly non-runtime proposal")
    if tuning.get("design_version") != VERSION:
        errors.append("Design version mismatch")
    if not re.fullmatch(r"[a-f0-9]{40}", tuning.get("baseline_commit", "")):
        errors.append("Missing exact baseline SHA")
    if not (tuning_path.parent / tuning["canonical_document"]).is_file():
        errors.append("Missing canonical case document")
    session = tuning["session"]
    if session["target_min_players"] != 1 or session["target_max_players"] != 4:
        errors.append("Target must preserve solo and at most four players")
    if session["vertical_slice_required_players"] != [1, 2] or session["inventory_slots"] != 3:
        errors.append("Vertical-slice/inventory contract changed without checker update")
    case = tuning["case_001_tutorial"]
    for name, value in case.items():
        if name.endswith(("_seconds", "_metres")) and (not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0):
            errors.append(f"Invalid proposal parameter: {name}")
    required_window = case["test_cycle_seconds"] + case["solo_round_trip_budget_seconds"] + case["safety_margin_seconds"]
    if case["promise_seconds"] < required_window:
        errors.append("Proposed promise window is shorter than declared solo work budget")
    canonical = (tuning_path.parent / tuning["canonical_document"]).read_text(encoding="utf-8")
    required_rows = {
        "Льготное отсутствие без обещания": "grace_seconds",
        "Предупреждение до поиска": "warning_seconds",
        "Окно обещания": "promise_seconds",
        "Тест цепи / перерыв радио": "test_cycle_seconds",
        "Спокойное наблюдение перед сдачей": "settled_observation_seconds",
    }
    for label, key in required_rows.items():
        expected = f"| {label} | {case[key]:g} с |"
        if expected not in canonical:
            errors.append(f"Canonical table differs from proposal: {key}")
    if errors:
        raise RuntimeError("\n".join(errors))
    report = {"markdown_files": len(documents()), "words_whitespace": words, "local_links": link_count, "agents_words": agents_words}
    print("GUESTS_DESIGN_OK " + json.dumps(report, ensure_ascii=False))
    return report


def source_sha() -> str:
    result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        return "unversioned-local-copy"
    return result.stdout.strip()


def anchor(path: Path) -> str:
    return "doc-" + re.sub(r"[^a-z0-9]+", "-", path.relative_to(ROOT).as_posix().lower()).strip("-")


def package() -> None:
    stats = check()
    out = ROOT / "build/docs"
    out.mkdir(parents=True, exist_ok=True)
    sha = source_sha()
    ordered = [ROOT / name for name in CHAPTERS]
    ordered.extend(path for path in documents() if path not in ordered)
    included = {path.resolve() for path in ordered}
    book: list[str] = [
        f"# ГОСТИ / GUESTS — полная дизайн-библия v{VERSION}\n\n",
        f"Исходный коммит: `{sha}`. Это целевой дизайн, не список готовых механик.\n\n",
        "Раздельные исходники и JSON предложенного баланса находятся в ZIP-комплекте.\n\n",
    ]
    for path in ordered:
        title = path.read_text(encoding="utf-8").splitlines()[0].removeprefix("# ")
        book.append(f"- [{title}](#{anchor(path)})\n")
    for path in ordered:
        text = path.read_text(encoding="utf-8")
        def rewrite(match: re.Match[str]) -> str:
            target = match.group(2)
            parsed = urlparse(target)
            if parsed.scheme or target.startswith("#"):
                return match.group(0)
            resolved = (path.parent / unquote(parsed.path)).resolve()
            if resolved in included:
                destination = "#" + anchor(resolved)
            elif resolved.is_relative_to(ROOT):
                relative = resolved.relative_to(ROOT).as_posix()
                ref = sha if re.fullmatch(r"[a-f0-9]{40}", sha) else "feature/bootstrap"
                destination = f"https://github.com/T-Damer/guests/blob/{ref}/{relative}"
            else:
                destination = target
            return match.group(1) + destination + match.group(3)
        book.extend([f'\n\n---\n\n<a id="{anchor(path)}"></a>\n\n', LINK.sub(rewrite, text)])
    combined = "".join(book).encode("utf-8")
    combined_path = out / f"{BASENAME}.md"
    combined_path.write_bytes(combined)
    info = {"design_version": VERSION, "commit": sha, "status": "design_not_implemented_game", "stats": stats, "combined_sha256": hashlib.sha256(combined).hexdigest()}
    info_bytes = (json.dumps(info, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    (out / "BUILD_INFO.json").write_bytes(info_bytes)
    start = "# Начните здесь\n\nОткройте docs/DESIGN.md для навигации или GUESTS-design-v0.2.md для чтения одним файлом.\n\nЭто проектная спецификация. Реализованные возможности перечислены отдельно в архитектуре.\n"
    archive_path = out / f"{BASENAME}.zip"
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in documents():
            archive.write(path, f"{BASENAME}/{path.relative_to(ROOT).as_posix()}")
        archive.write(ROOT / "docs/design/tuning.v0.2.json", f"{BASENAME}/docs/design/tuning.v0.2.json")
        archive.writestr(f"{BASENAME}/{BASENAME}.md", combined)
        archive.writestr(f"{BASENAME}/BUILD_INFO.json", info_bytes)
        archive.writestr(f"{BASENAME}/START_HERE.md", start)
    checksum = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    (out / f"{BASENAME}.zip.sha256").write_text(f"{checksum}  {archive_path.name}\n", encoding="utf-8")
    print(f"GUESTS_DESIGN_PACKAGE_OK {archive_path.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["check", "package"])
    args = parser.parse_args()
    if args.command == "check":
        check()
    else:
        package()


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
        print(f"GUESTS_DESIGN_FAILED: {error}", file=sys.stderr)
        sys.exit(1)
