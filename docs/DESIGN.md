# Design contract — first care shift

## Identity

A penal night-shift crew services an anomalous residential institute. Mutated residents retain habits, needs and fragments of their lives. The fantasy is competent, frightening care under constraints, not extermination. The fictional fungal syndrome is not a depiction of real fungal disease or psychiatric patients.

The institution and resident histories are original. Lost Archive / K.O.N.T.U.R. is an atmospheric reference, not licensed canon to copy. Use the working title GUESTS until naming is decided.

## Loop

Receive a compact work order -> inspect what changed -> prepare light/equipment/contact -> perform care -> address consequences -> decide whether to investigate further -> return to a genuinely safe staff post.

Target a 15–25 minute eventual shift, but the bootstrap is intentionally shorter. Every later task should change the situation, not merely fill a progress bar. Knowledge of a resident stays reliable; circumstances combine in new ways. Do not invert learned rules randomly.

The bootstrap work order is: restore power, bring the portable lamp, introduce yourself, establish radio support, return to the logbook. It demonstrates state changes and recoverable mistakes, not final repeatability or narrative depth.

## Resident 027: The Waiting One

Human need: know someone will return. Initial state is calm; no hidden punishment timer before first contact. After introduction, a nearby visible caregiver or a powered radio supports calm. Without support, a grace interval precedes a warning; an unanswered warning escalates to searching. The visible neck/head stretch reflects that escalation.

A promise creates a finite work window. While the caregiver remains present, the waiting allowance has not yet been spent. When away without radio support, time is consumed. Expiry produces a warning, not immediate death. Radio support or returning contact recovers the situation. Timing is data in `content/guests/027_waiting.tres`.

Current searching state has no locomotion or capture. Add those only with observation-based navigation and counterplay tests. Never let a renderer, animation event or postprocessing setting decide a rule.

## First-slice limits

| Area | Ceiling |
|---|---|
| Floor | One authored corridor, staff room and resident room |
| Residents | One complete before a second |
| Players | Bootstrap solo; next milestone two, eventual maximum four |
| Inventory | Three slots; initially two reusable-system item types |
| Combat | None; eventual recovery through contact, obstacles, escape and rescue |
| Networking | One authority, no host migration or mid-shift join in first playable coop |
| Physics | Character movement and simple static colliders; no physical dragging, cables or destructible rooms |
| Content generation | No runtime LLM and no procedural floor generator |
| Progression | No currencies, shop or persistence until a shift is worth replaying |

## Fairness and atmosphere

The staff post is reliable safety. Ordinary lamps improve observation and working conditions; they are not universal anti-monster weapons. Not every resident becomes aggressive. Numbered records never replace human motives.

A failure must be explainable by observable information. First setbacks should permit recovery. Future hiding uses actual senses and remembered positions, not omniscient tracking. A teammate should not spend minutes holding an 'entertain resident' button; agreements create useful time windows.

Readable silhouettes, familiar domestic scale and restrained motion carry the horror. Keep some encounters well enough lit to see the abnormal proportions. Camera grain is seasoning, not concealment of poor art. Noise/chromatic effects must be disableable without changing difficulty.

## Acceptance before expansion

A new player can identify the next useful action. A failed promise is understandable and recoverable. An item cannot be duplicated or spent from another actor's inventory. Finishing requires the declared state, not just visiting an exit. Then test replay with humans: did they discuss a choice, or only repeat a sequence? No automated test can answer that last question.
