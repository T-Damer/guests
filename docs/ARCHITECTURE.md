# Architecture and ownership

## Current modules

`game/domain/` contains typed RefCounted state and a Resource definition. It knows neither scene nodes nor clocks, devices, networking or presentation. `CareState.tick` receives elapsed time and observations. `ShiftState` owns unique items and per-actor inventories. Snapshot arrays are copied. `GuestProfile` is shared immutable configuration, never instance state.

`game/presentation/` translates input into intentions and domain state into mesh/light/audio/UI changes. `main.gd` currently orchestrates the **solo** scene, including range/line-of-sight checks. Scene nodes and `.tres` files remain editable in Godot. The wall module exposes dimensions to the editor and creates only its own internal meshes/shapes; do not scale physics bodies or hand-edit those generated internals.

`game/network/NetSession` is a separate server-authoritative ENet adapter. Peers send action IDs; sender identity comes from the transport. Unknown actions, excessive requests and absent/false reach validators are rejected. The authority owns the state and inventories. Disconnect returns unplaced critical items to their supply points. The two-process test checks this transport contract. **The adapter is not yet wired to player locomotion or the solo scene.**

`tests/` uses a small native assertion runner and an ENet fixture, not a custom test framework. GdUnit4 can be considered when fixtures/doubles justify a pinned dependency. Do not vendor a test addon merely because it was mentioned during brainstorming.

`tools/` is Python 3.11+ standard-library development tooling. It is not part of the game or its future server. No Node.js backend or duplicate rules implementation.

## Decisions

**ADR-001 — Compatibility for the first PS1 preset.** PC-first Godot 4.7.2 stable, typed GDScript, real-time local lighting/shadows; no dynamic GI requirement. Compatibility keeps this narrow lighting workload and software-rendered checks simple. Forward+ was considered for realism but is not needed to prove this game loop. Revisit only with a measured visual requirement and target-hardware evidence. This does not promise browser support: ENet is not a browser transport.

**ADR-002 — No bespoke ECS/event-bus framework.** Prefer Godot nodes/signals/resources, pure state where it improves testing, and direct explicit coordination for this small slice.

**ADR-003 — Deformation is presentation-only.** The resident's neck/head move; interaction anchors and collision do not scale implicitly. Future navigation must account explicitly for maximum silhouettes and traversal states.

**ADR-004 — Reproducible asset resolution.** Six approved GLBs are resolved from one SHA-256-pinned CC0 archive. Cache/vendor folders are generated and ignored. Exported games contain the resolved resources and need no network. Keep modified source art outside vendor with new provenance.

## Next network boundary

Do not expose `main.gd` state setters to clients. Next implement authoritative actors, server-observed range/occlusion and synchronized interactable states, then camera-only local look and measured prediction/interpolation. Server time drives care. UI and audio react to confirmed state. Scope joins to the lobby before the shift; cleanly reject unsupported mid-shift joining.

Before calling coop playable: two actual clients complete the shift, simultaneous pickup resolves once, out-of-range/occluded/spoofed actions fail, repeated packets do not repeat outcomes, host exit is explicit, a disconnected item holder cannot soft-lock progress, and latency/loss cases have evidence.

## File ownership

The integration owner owns `project.godot`, shared scenes, wire enums, manifest structure and workflows. A behavior task owns the relevant domain file/profile/tests; an art task owns its isolated source/model/material and preview scene. Shared-file edits are serialized. Never parallel-write a `.tscn` or silently regenerate over a human's edits.
