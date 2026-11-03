# PM DevCoords — development notes

## Scope implemented

- Standalone FiveM utility with ox_lib; no QBX dependency.
- Aim-point capture using a synchronous camera raycast; no ped-position capture.
- `vector3` and `vector4` Lua output; vector4 defaults to camera-facing heading.
- User-defined groups, optional subgroups, collections and point names.
- Ordered point capture, review, last-point undo and collection switching.
- Immediate server-side persistence in `captures.json`.
- Export a named group to `exports/<group>.lua`, including nested subgroup tables.
- ACE access using `IsPlayerAceAllowed(source, 'command.devcoords')`.

## Controls

- `/devcoords`: toggle pointer; menu opens automatically.
- `/devcoordsmenu`: reopen ox_lib menu.
- J: capture point while tool is active.
- K: undo last point while tool is active.
- No M keybind; it is reserved for the server phone.

## Server setup

Install the resource directory containing `fxmanifest.lua` as `pm-devcoords`, ensure `ox_lib` first, and ensure `pm-devcoords` afterward. The resource uses existing ACE command permissions. Administrators must have `command.devcoords` allowed (either directly or through their inherited administrator command ACE permissions). Do not add citizen ID or license allowlists.

## Verification status

Code changes are committed, but FiveM runtime testing has not been performed here. In-server validation is still required for raycast hit placement, camera heading, ACE access, menu interaction, resource restart persistence, and actual Lua file creation. These are runtime checks, not additional planned features.

Original author: LuckyyFishyy (yy-devcoords). Preserve the upstream License.txt.
