# PM DevCoords — implementation reference

## Architecture

- `fxmanifest.lua`: FiveM resource definition, ox_lib initialization, NUI overlay assets.
- `shared/config.lua`: raycast distance, marker, and line styling.
- `client/main.lua`: aim raycast, pointer drawing, ox_lib menus, input mappings, NUI updates.
- `server/main.lua`: ACE checks, capture storage, undo, JSON persistence, Lua export.
- `html/index.html`, `html/script.js`, `html/style.css`: **read-only coordinate overlay**; ox_lib handles menus.
- `exports/.gitkeep`: keeps the server export directory present in Git.

## Behavior and storage

- `/devcoords` requires `command.devcoords` ACE; server-side create/capture/undo/export/request events check ACE as well.
- Captures use a camera-based synchronous shape test and world hit coordinates, falling back to the ray endpoint if no hit. The synchronous test runs at most every 50 ms while the marker and line draw each frame.
- `vector4` heading is converted from gameplay camera rotation to GTA heading via `(-rot.z) % 360`, independent of player heading.
- The NUI message contract is `action=open|close|update`, with `vector3`, `vector4`, and `context` on update. HTML element IDs use `pm-devcoords-`.
- Server stores groups as `groups[group][collection] = { points... }`; optional subgroups are represented by `Subgroup/Collection` keys and expanded into nested Lua tables during export.
- Capture names default to server-assigned `Point_01`, `Point_02`, etc. Named points use supplied names.
- `captures.json` is written after changes using `SaveResourceFile`; data is read on resource start and sent to authorized clients.
- `exports/<group>.lua` is generated on the server. Both `vector3` and `vector4` use full constructor names.
- No `M` key mapping. `J` and `K` mappings are registered but handlers only operate while the tool is active.
- No QBX, ox_target, ox_inventory, PolyZone creation, citizen ID or license allowlists.

## Installation and verification

Install the inner `pm-devcoords` folder, ensure `ox_lib` first, then `pm-devcoords`. Configure `add_ace group.admin command.devcoords allow` or equivalent inherited administrator ACE. Actual file writes occur under the server's installed resource directory; preserve `captures.json` and generated exports when updating.

**Runtime verification has not been performed here.** In FiveM check: (1) permitted and denied users; (2) menu opening, group/collection creation and selection; (3) camera aim and vector4 heading; (4) J capture, named capture, review and K undo; (5) restart and resume; (6) export file existence and Lua structure. Fix any issues observed in those tests before declaring a validated release.

## Attribution

Derived from yy-devcoords by LuckyyFishyy; original license preserved.
