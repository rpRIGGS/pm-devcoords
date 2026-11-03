# PM DevCoords development

Standalone PowerMoves developer utility. No QBX, inventory integration, or polygon creator.

## Implemented in code

- Server-side ACE authorization via `command.devcoords`.
- `/devcoords` toggles aim pointer and automatically opens the ox_lib menu.
- `/devcoordsmenu` reopens the menu; no M keybind (reserved for phone).
- J captures the aimed world point; K undoes the last capture, while active.
- `vector3` or `vector4` selection, default `vector4`; heading comes from camera aim direction, not ped position.
- Freely named groups and collections, with an optional subgroup (for example `Vineyard_01A / Row_01 / SideA`).
- Auto-numbered or individually named points; point review.
- Immediate server-side persistence in `captures.json`.
- Finalize/export selected group to `exports/<group>.lua`, with nested subgroup tables.

## Verification

Not yet run in a FiveM server. Validate pointer raycast, ACE access, ox_lib menu, saving, reloading, undo, and Lua exports before calling this release tested.

## Original project

Based on yy-devcoords by LuckyyFishyy. Preserve the original License.txt.
