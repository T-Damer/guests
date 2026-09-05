# 001 — Runnable solo care slice + AI development contract

Status: implementation; verification recorded by CI for each exact commit.
Branch: `feature/bootstrap`. Integration owner owns the full empty-repository bootstrap. One PR, no automatic merge or stable branch.

## Contract

An ordinary Godot project, not a generated application framework. A player can move through the post/corridor/resident room, collect two items into a three-slot inventory, repair power, place light, establish contact, make a time-limited promise, toggle radio and submit a completed shift. Resident warning/deformation is visible and recoverable. Safe post, original proxy resident and existing licensed furniture.

Pure rules have isolated per-actor inventories and detached snapshots. A separate two-process ENet fixture proves server action approval, duplicate pickup rejection, unknown action rejection and returning a disconnected holder's critical item. Do not call this full playable coop.

## Required evidence

`setup`, `check`, `capture`, `export`; retained exact-source archive, SHA, logs and captures. Review real rendered images. Mark audio listening and human playtest NOT RUN until performed. Do not infer Windows/macOS results from Linux.

## Not in this task

Player networking/prediction, matchmaking, movement/chase/capture AI, hiding, persistent saves, more residents, procedural rooms, final narrative, final audio and polished character art.

## Next

Proceed to task 002 only after bootstrap defects are resolved. Do not add a second resident to avoid finishing the first cooperative shift.
