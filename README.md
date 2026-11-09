# PM DevCoords

**PM DevCoords is the unified QBCore developer toolkit for PowerMoves RP.** One ox_lib menu (`/devadmin`) combines pointer-based coordinate capture, entity inspection, vehicle developer utilities, and selected tools adapted from qb-adminmenu.

This is **one resource**, not two admin scripts. Coordinate capture remains a feature within the developer menu, including persistent grouped captures and readable `.txt` exports. Individual developer chat commands remain available.

## Install

1. Copy the **inner `pm-devcoords/` folder** (the one containing `fxmanifest.lua`) into your server resources directory. Do not install the entire GitHub repository as the resource.
2. Install and start `qb-core`, `ox_lib`, and `oxmysql` before this resource.
3. Add `ensure pm-devcoords` after those dependencies in `server.cfg`.
4. No new ACE permission is required. Access uses your existing QBCore `admin` or `god` permissions.

## Main menu and commands

Run `/devadmin` to open the unified developer menu.

- `/devadmin`: open the unified PM DevCoords developer menu.
- **Coordinate collector** in the main menu: start or stop the pointer capture overlay and open its collection menu.
- `/devcoordsmenu`: reopen the menu while the tool is active.
- `J`: capture the aimed point into the selected collection.
- `K`: undo the last point in the selected collection.
- No `M` shortcut: that key remains available to your phone.

Use the menu to create or select a group and collection. An optional subgroup can organize collections such as `Vineyard_01A / Row_01 / SideA`. You can also use flat collections. The menu lets you choose `vector3` or `vector4`, capture a named point, review saved points, undo, and finish/export a group.

Captured points are written to `captures.json` in the resource directory. **Finish / Export group (.txt)** writes `<group>.txt` within the resource. These files are created on the server, not downloaded to the client. Preserve them when updating the resource.

## Validation status

GitHub Actions tests cover Lua syntax, collector persistence/export and permission guards, developer commands, client menus, entity-viewer behavior, and the NUI overlay using mocked FiveM APIs. **Not yet tested in a running FiveM server.** In-game verification must cover raycast placement, menu controls, existing QBCore admin/god permissions, persistence after restart, text export, entity network control, and vehicle database saving.

## Credits

Original project: [yy-devcoords](https://github.com/LuckyyFishyy/yy-devcoords) by LuckyyFishyy. Original license retained in `pm-devcoords/License.txt`.

## Vineyard capture example

1. Run `/devadmin`, select **Coordinate collector**, and choose **New group / collection**: Group `V01A`, Subgroup `Row_01`, Collection `SideA`.
2. Aim at each position and press **J**. Each capture immediately saves to `captures.json`; no separate save action is needed.
3. Reopen the menu with `/devcoordsmenu`, create `V01A / Row_01 / SideB`, and capture Side B points with **J**.
4. Continue with other rows as needed. Choose **Finish / Export group (.txt)** to write `V01A.txt` and clear the selection **after a successful export**.
5. Select **Coordinate collector** again to close the capture overlay. The JSON remains saved even if you do not export; text exports are snapshots and should be regenerated after later edits.

The `.txt` file contains readable named Lua-style `vector3(...)` / `vector4(...)` coordinates, grouped by row and side, suitable for copying into chat. It is stored on the **server**, not automatically downloaded to your PC's client folder.

## Integrated developer tools

Use **/devadmin** to open the unified ox_lib developer menu. Selected qb-adminmenu developer features are integrated into this single PM DevCoords resource alongside the original pointer-based coordinate collector.

- **Coordinates:** /vector2, /vector3, /vector4, /heading, /coords; two-decimal clipboard output and live vector4 HUD. The pointer collector is launched from the unified menu and retains /devcoordsmenu, J capture, K undo, group/row/side selection and .txt export.
- **Vehicles:** /maxmods applies the original performance slots (11, 12, 13, 15, 16, turbo); /admincar saves the driven vehicle's properties into QBCore player_vehicles after server-side driver, model and plate validation. Vehicle developer HUD displays entity ID, net ID, model name/hash, engine and body health.
- **Entity viewer:** original qb-adminmenu raycast, detailed aimed entity panel, 3D bounding boxes, nearby objects/vehicles/peds, 5–50m radius, E delete, G freeze/unfreeze, H copy pointed vector3, and full entity information clipboard output. The viewer supports an independently toggled free-aim mode.
- **Additional developer commands:** `/setmodel <model> [player id]` changes a ped model (including an online player ID when specified). Waypoint teleport is available from the ox_lib menu.

**Excluded intentionally:** vehicle spawning, /repair, /dv, NoClip, god mode, high jump and running-speed changes, which are already provided by Legend or txAdmin. There is no reason to duplicate those features. The original qb-adminmenu vehicle category browser belongs to its vehicle spawner and is likewise excluded.

**Permissions:** All PM DevCoords features use QBCore's existing `admin` or `god` permission checks. No custom `command.devcoords` ACE grant is needed.

**Validation:** GitHub Actions checks Lua syntax and the repository's automated tests. Live FiveM verification remains required for client natives, entity controls, clipboard, /admincar database writes, and coexistence with Legend/txAdmin. A passing CI run is not a claim of successful in-game testing.
