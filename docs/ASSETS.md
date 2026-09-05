# Art direction and asset intake

## PS1-inspired, not hardware emulation

Use restrained domestic realism: green painted lower walls, dirty plaster, linoleum, pipes, ordinary furniture and human proportions before abnormal stretching. The prototype uses a 480x270 postprocess sampling grid, nearest sampling, limited color steps and subtle noise/chromatic separation. F8 disables the entire effect; gameplay and important warnings remain intact.

Dynamic local lights and shadows stay. No dynamic global illumination, filmic motion blur, dense fog or CRT distortion as prerequisites. The safe post is warm; corridors are darker; the resident must sometimes be clearly visible. The original mannequin and oscillator tones are explicit proxies, not final art/audio.

## Starting budgets (review targets)

Aim for 500–1500 triangles per final resident, 100–1000 for a common prop, and 64–256 pixel textures where useful. Exceptions need a measured reason, not automatic decimation. Currently the scene has at most three shadowed sources: staff lamp, corridor lamp and player flashlight; the bedside light is unshadowed. Four-player lighting must be profiled separately before enabling every player's shadowed flashlight.

These visual budgets are review targets; `check_repo.py` does not pretend to measure every triangle or GPU cost. Asset intake does enforce archive/member size and checksums.

## Existing assets actually connected to the scene

Kenney Furniture Kit, CC0: bedSingle, chair, cabinetBed, radio, lampSquareFloor, bookcaseClosedWide. The source page and exact archive URL are in `assets/manifest.json`. The downloaded archive's own License.txt identifies Furniture Kit 2.0 even though the page lists an older update label. The archive and each selected model/license have pinned SHA-256 values.

Run `python3 tools/assets.py`, or the normal `prepare` command. Only selected GLBs and the original license are written to ignored `assets/vendor/kenney-furniture`. A changed upstream archive fails closed. No scraped meshes, video frames, commercial-game assets or ambiguous marketplace licenses are accepted.

## New asset contract

State the purpose, scale in metres, maximum extent, polygon/material/texture budget, source/author/license/checksum, import settings, interaction anchors, collision proxy, animation states and required captures. Keep original sources in a separately named source area; never edit generated vendor output and expect it to survive `prepare`.

Godot scenes own placement and static collision proxies. Visual instances may be uniformly scaled; physical shapes use explicit sizes. Capture both the normal and maximum-stretch poses. Check doors, ceiling, shadows, readability with F8 off, and whether a teammate can identify the warning. Inspect the actual exported build.

No custom font files are required; the UI uses the engine's built-in font. Audio licensing and listening approval are separate from graphical approval.

## Import-pivot correction
The selected GLBs use corner/offset origins. Instance positions and collision proxies in `main.tscn` are adjusted to their measured imported bounds. Do not assume every downloaded prop has a centered origin or identical scale. The cabinet now supports the radio and the chair faces the same direction as the resident.
