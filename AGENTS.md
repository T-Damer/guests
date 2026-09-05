# GUESTS — agent entry point

PC-first Godot 4.7.2, typed GDScript, PS1-inspired domestic horror. The product is cooperative (target 1–4), with a complete solo path. Existing bootstrap is still solo plus a separate ENet probe: do not call it playable online.

## Read on demand
Read the active task, inspect current code/tests and use `docs/DESIGN.md` as the index. Do not load the entire design library into every task. Architecture: `docs/ARCHITECTURE.md`; production rules: `docs/WORKFLOW.md`; assets: `docs/ASSETS.md`; milestones: `docs/ROADMAP.md`.
- Resident 027 / first case: `docs/design/05-case-001.md` (canonical rules).
- Hub, menu, elevator: `02-player-journey.md` and `07-ui-ux.md` under `docs/design/`.
- Inventory/cooperation: `docs/design/04-gameplay-coop.md` and relevant architecture sections.
- Art/audio/story: only the corresponding numbered design document and owned assets.
`docs/design/tuning.v0.2.json` is a proposal, NOT runtime input. Design describes targets, code/evidence describe what exists. Do not silently implement the whole bible.

## Hard boundaries
One hub floor, one lift, one short arrival view, one case and one complete resident first. No combat, parkour, procedural city, public MMO hub, bespoke ECS, runtime LLM or required microphone. The staff floor stays safe. Rules are readable and consistent; at least one solution works solo. Extra dossiers are backlog, not parallel implementation tasks.

## Change discipline
1. Inspect worktree, remote head, branches, open PRs and existing solutions. Preserve human edits. Search -> reuse -> extend -> compose -> create.
2. One explicit task with owned paths, non-goals and observable acceptance. Maximum two parallel writers with disjoint files; shared scenes/settings/wire contracts have one owner.
3. At most five branches and three open PRs. Bootstrap uses one feature branch and PR. `main` integrates; `stable` publishes separately approved verified commits. No force push, silent overwrite, auto-merge or stable promotion.
4. Typed interfaces; named gameplay IDs, durations and thresholds. Do not invent meaningless constants for structural zero/one or every blockout coordinate.
5. Domain has no scene tree, input, clock, renderer or transport dependency. Inject time/observations. Separate shared immutable Resources, instance state and presentation.
6. One authoritative simulation for solo/online. Clients request intentions; validate sender, phase, version, IDs, rate, distance, occlusion and inventory. Repeated requests cannot repeat outcomes.
7. Visual deformation does not implicitly scale physics. Graphics/audio settings do not change perception rules. Animations show outcomes; they do not decide authority.
8. Prefer built-ins and existing code; new runtime dependencies need an explicit architecture decision. Pin tools. No duplicated Node.js game server.
9. Imported assets require actual provenance/license/version/checksums. No ripped game/video assets or copied canon. Mark proxies honestly; never fabricate hashes for shortlisted assets.
10. Test success, failure and boundary cases. Network work needs separate processes and a real duo playthrough before online claims. Never weaken tests merely to pass.
11. Visual work needs runtime captures and inspection; audio needs listening. Headless/Dummy passes prove neither appearance, sound, fun nor FPS.
12. Report exact SHA, commands, evidence, PASS/FAIL/NOT RUN and remaining gaps. Never disclose credentials or upload private user data.

## Commands and handoff
`python3 tools/dev.py check` — current game checks; `capture` — rendered fixtures; `export` — Linux. `python3 tools/package.py all` — standalone packages. `python3 tools/design.py check` / `package` — design validation/export, not gameplay verification.

Human editors use ordinary scenes/Resources and art sources. Agents implement, verify, document deltas and update the same PR; humans retain creative and merge/release approval. Track `.gd.uid`/shader UIDs, not `.godot/` or generated vendor caches. Next gameplay contract: `docs/tasks/002-coop.md`.
