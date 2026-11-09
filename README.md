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

## Developer utilities restored from qb-adminmenu

Use **`/devadmin`** for an ox_lib development menu. It provides: existing pointer/group coordinate collector, copy player `vector2`, `vector3`, `vector4`, heading to clipboard, live coordinate HUD, vehicle spawn by model, delete, max upgrades, vehicle developer HUD, full entity free-aim inspection (E delete, G freeze/unfreeze, H copy aimed coordinates), nearby object/vehicle/ped information, entity model copy, waypoint teleport, and save current vehicle to your player garage database.

Restored slash commands: **`/vector2`**, **`/vector3`**, **`/vector4`**, **`/heading`**, **`/coords`**, **`/admincar`**, and **`/devadmin`**. Existing **`/devcoords`** and **`/devcoordsmenu`** remain unchanged. The vector commands copy your **player's** location; the pointer collector captures the aimed world position. `/admincar` requires you to be driving a model listed in `QBCore.Shared.Vehicles`; the vehicle plate must not already be in `player_vehicles`. Vehicle spawning is temporary; `/admincar` registers it in the QBCore vehicle database.

Access: ACE `command.devcoords` **or** QBCore `admin`/`god` permissions. The existing coordinate collector retains its original ACE requirement, so grant `command.devcoords` to admins who need that collector. This resource does not replace Legend's server/player administration features.

**Status:** automated checks are not a substitute for testing the development menu and QBCore garage schema in a live FiveM server. The NoClip and vehicle utilities should be verified in-game before relying on them.

### Original qb-adminmenu entity-view controls

Open `/devadmin` → **Entity viewer: free aim (E/G/H)**. Aim at an object, vehicle, or NPC to see its model hash, entity ID, network ID, heading, and position. **E** deletes the targeted entity, **G** freezes/unfreezes it, and **H** copies the aimed world coordinates as `vector3(...)` to the clipboard. The nearby-object, vehicle, and ped views can be toggled independently; their inspection radius is adjustable. Avoid deleting map/world objects you need; deletion is not undoable. These are client-side developer utilities, not replacements for server-wide persistent world editing.

Legend already supplies repair and NoClip, so the new `/devadmin` menu does not duplicate those entries. The prior internal NoClip/repair helper code is not exposed in the menu.
