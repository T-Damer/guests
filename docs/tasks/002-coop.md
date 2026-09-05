# 002 — Two people complete the same care shift

Status: proposed; not implemented by bootstrap.
Dependencies: accepted 001 and one reproducible source/build baseline.
Owned paths: networking, actor controller, integration scene and network/playthrough tests. Assign one owner to shared scene/wire IDs before parallel work.

## Contract

A host and one client join before starting, see each other, perform the existing care tasks and finish one shared shift. No client-supplied success, item ownership or teleport coordinates. Server physics/observations determine action range, occlusion and care contact; no client renders a different effective rule.

## Acceptance

Two real processes complete the existing work order. Simultaneous pickup has one winner. A client cannot operate a distant or wall-occluded target. Repeated/stale requests do not duplicate inventory or progress. A dropped item holder returns critical unplaced items to supply. Host departure shows a clear end state. Unsupported mid-shift joins are explicitly rejected.

Add an automated scenario with bounded latency/loss and record the actual parameters. Capture both client views for the same state. Test local look separately from authoritative movement; introduce interpolation/prediction only with evidence of the problem it solves.

## Non-goals

No new resident, floor, shop, engine abstraction, migration, backend account system or relay vendor commitment. The current ENet fixture remains a transport test, not the final playthrough.
