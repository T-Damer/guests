# 003 — Standalone Linux and macOS packages

Status: implementation / verify exact commit in Package desktop clients workflow.
Scope: packaging only; no gameplay changes, additional branch, merge or release promotion.
Owned paths: project.godot (dual texture import only), export_presets.cfg, tools/package.py,
tools/export_notices.gd + UID, tools/distribution/, tests/test_packaging.py,
.github/workflows/package.yml, README.md and this contract.

## Contract

Build both targets on Linux with the pinned official Godot templates. Linux gets a
standalone x86_64 ELF, adjacent PCK, a working-directory-independent start.sh and
instructions in a permission-preserving tar.gz. macOS gets a Universal 2 .app in
ZIP with built-in ad-hoc signing; no Developer ID, notarization or credential use.
No install-time download, sudo or global Gatekeeper change in either package.

Each package contains source SHA, build facts, file checksums and license notices.
A dirty checkout may not be labelled with a clean commit SHA. The raw export is
checked for architecture, app metadata, resources and executable bits. Native
macOS signature verification and headless execution are a separate CI job; never
attribute a Linux-only structural check to a real Mac launch or interactive test.

Godot requires ETC2/ASTC imports for Apple Silicon and S3TC/BPTC for Intel.
Both project import options are enabled; the game renderer and art are unchanged.

## Checks

python3 -m unittest discover -s tests -p test_packaging.py
python3 tools/dev.py check
python3 tools/package.py all

CI retains exact-source evidence and packages. No automatic publish/merge. Existing
manual gameplay/audio review and shutdown-object warning remain open. Changes do
not turn the transport test into a playable cooperative game.
