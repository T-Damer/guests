# GUESTS — agent entry point

Read `README.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md` and the active task before editing. Full workflow: `docs/WORKFLOW.md`; art intake: `docs/ASSETS.md`.

## Scope
- PC-first Godot, typed GDScript, PS1-inspired restrained realism; not a browser game or a reusable engine.
- One floor, one resident, one complete care shift first. No combat, procedural floor generator, live LLM dialogue or bespoke ECS.
- Keep human habits and readable warnings. Light is useful; the staff post stays safe.

## Change discipline
1. Inspect the working tree, branches, open PRs and existing implementations. Never overwrite another contributor's work.
2. Search -> reuse -> extend -> compose -> create. One task, explicit owned paths, small reviewable commits.
3. Maximum five branches total and three open PRs. `main` integrates; `stable` publishes verified builds. Start with one feature branch and one PR. No force pushes, automatic merging or release promotion.
4. One integration owner. Parallel writers require disjoint files. Shared scenes, project settings and wire contracts have one writer.
5. Typed inputs/outputs. Gameplay IDs, thresholds, durations and budgets live in named definitions, not anonymous literals. Do not wrap structural zero/one or every local layout coordinate in meaningless constants.
6. Domain rules have no scene tree, clock, input, renderer or networking dependencies. Inject elapsed time. Separate immutable definitions, per-instance state and presentation.
7. The server decides shared outcomes. Clients request intentions. Validate sender, type, distance, inventory, rate and phase. Never accept client-reported successful outcomes or teleport positions.
8. Use Godot's built-ins before new dependencies. Pin tools and addons; request an architecture decision for a new runtime dependency.
9. Every imported asset needs provenance, license, version and checksum. No ripped game assets, unlicensed videos, logos or copied K.O.N.T.U.R./SCP lore. Generated proxies must be labelled honestly.
10. Gameplay changes require success and failure tests; network changes require multiple processes. Never weaken a test to make a build green.
11. Visual work requires a rendered scene/capture; audio needs a listening check. A headless pass proves neither appearance, sound, fun nor frame rate.
12. Never report unrun checks as passed. Report exact commit, commands, outcomes, evidence and remaining gaps. Do not expose credentials or include them in logs/artifacts.

## Human / AI handoff
The AI implements, tests, documents deltas and proposes a PR. A human can edit ordinary scenes and resources, chooses artistic direction and approves merges/releases. Preserve editor-authored work; keep `.godot/`, binaries and temporary captures out of Git.

Repository is in bootstrap. Referenced documents and commands are delivered in the same bootstrap PR; do not treat this initial tooling commit as a playable game.
