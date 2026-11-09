# PM DevCoords

Standalone FiveM developer coordinate capture and utility menu for PowerMoves RP, based on yy-devcoords by LuckyyFishyy.

Aim at a world surface (a successful raycast hit is required to save), capture `vector3(...)` or `vector4(...)` coordinates, organize points by named groups and collections, and save/export them to a plain-text coordinate file.

## Install

1. Copy the **inner `pm-devcoords/` folder** (the one containing `fxmanifest.lua`) into your server resources directory. Do not install the entire GitHub repository as the resource.
2. Install and start `qb-core`, `ox_lib`, and `oxmysql` before this resource.
3. Add `ensure pm-devcoords` after those dependencies in `server.cfg`.
4. Grant your existing administrator group the ACE `command.devcoords`, for example `add_ace group.admin command.devcoords allow`. This does not require player identifiers in the script.

## Use

- `/devcoords`: toggle the tool; the ox_lib menu opens on activation.
- `/devcoordsmenu`: reopen the menu while the tool is active.
- `J`: capture the aimed point into the selected collection.
- `K`: undo the last point in the selected collection.
- No `M` shortcut: that key remains available to your phone.

Use the menu to create or select a group and collection. An optional subgroup can organize collections such as `Vineyard_01A / Row_01 / SideA`. You can also use flat collections. The menu lets you choose `vector3` or `vector4`, capture a named point, review saved points, undo, and finish/export a group.

Captured points are written to `captures.json` in the resource directory. **Finish / Export group (.txt)** writes `<group>.txt` within the resource. These files are created on the server, not downloaded to the client. Preserve them when updating the resource.

## Status

Automated GitHub Actions checks cover Lua syntax, mocked server and client behavior, and the NUI overlay. **Not yet tested in a running FiveM server**. The in-game test must confirm raycast placement, menu controls, ACE permission, persistence after restart, and text export creation.

## Credits

Original project: [yy-devcoords](https://github.com/LuckyyFishyy/yy-devcoords) by LuckyyFishyy. Original license retained in `pm-devcoords/License.txt`.

## Vineyard capture example

1. Run `/devcoords` and choose **New group / collection**: Group `V01A`, Subgroup `Row_01`, Collection `SideA`.
2. Aim at each position and press **J**. Each capture immediately saves to `captures.json`; no separate save action is needed.
3. Reopen the menu with `/devcoordsmenu`, create `V01A / Row_01 / SideB`, and capture Side B points with **J**.
4. Continue with other rows as needed. Choose **Finish / Export group (.txt)** to write `V01A.txt` and clear the selection **after a successful export**.
5. Run `/devcoords` to close the tool. The JSON remains saved even if you do not export; text exports are snapshots and should be regenerated after later edits.

The `.txt` file contains readable named Lua-style `vector3(...)` / `vector4(...)` coordinates, grouped by row and side, suitable for copying into chat. It is stored on the **server**, not automatically downloaded to your PC's client folder.

## Developer tools ported from qb-adminmenu

Use **/devadmin** to open the ox_lib developer menu. The original qb-adminmenu developer tools are integrated into this single PM DevCoords resource, alongside the original pointer-based coordinate collector.

- **Coordinates:** /vector2, /vector3, /vector4, /heading, /coords; two-decimal clipboard output and live vector4 HUD. The pointer collector retains /devcoords, /devcoordsmenu, J capture, K undo, group/row/side selection and .txt export.
- **Vehicles:** /maxmods applies the original performance slots (11, 12, 13, 15, 16, turbo); /admincar saves the driven vehicle's properties into QBCore player_vehicles after model, plate and ownership validation. Vehicle developer HUD displays entity ID, net ID, model name/hash, engine and body health.
- **Entity viewer:** original qb-adminmenu raycast, detailed aimed entity panel, 3D bounding boxes, nearby objects/vehicles/peds, 5–50m radius, E delete, G freeze/unfreeze, H copy pointed vector3, and full entity information clipboard output. The viewer supports an independently toggled free-aim mode.
- **Additional developer commands:** /setmodel <model> [player id],. Waypoint teleport is available from the ox_lib menu..

**Excluded intentionally:** vehicle spawning, /repair, /dv, NoClip, god mode, high jump and running-speed changes, which are already provided by Legend or txAdmin. There is no reason to duplicate those features. The original qb-adminmenu vehicle category browser belongs to its vehicle spawner and is likewise excluded.

**Permissions:** /devadmin and developer slash commands require ACE `command.devcoords` or QBCore admin/god. The original pointer collector continues to require ACE `command.devcoords`. Use `add_ace group.admin command.devcoords allow` (or an equivalent principal grant) if appropriate for your server permissions.

**Validation:** GitHub Actions checks Lua syntax and the repository's automated tests. Live FiveM verification remains required for client natives, entity controls, clipboard, /admincar database writes, and coexistence with Legend/txAdmin. A passing CI run is not a claim of successful in-game testing.
