-- Runs against real server/main.lua with mocked FiveM APIs.
local commands, events, files, notices = {}, {}, {}, {}
local authorized = { [1] = true, [2] = false }
local failWrites = false
GetCurrentResourceName = function() return 'pm-devcoords' end
IsPlayerAceAllowed = function(src, ace)
    assert(ace == 'command.devcoords')
    return authorized[src] or false
end
RegisterCommand = function(name, fn) commands[name] = fn end
RegisterNetEvent = function(name, fn) events[name] = fn end
TriggerClientEvent = function(name, target, ...)
    notices[#notices + 1] = { name = name, target = target, args = {...} }
end
LoadResourceFile = function(_, name) return files[name] end
SaveResourceFile = function(_, name, content)
    if failWrites then return false end
    files[name] = content
    return true
end
local cjson = require('cjson')
json = { encode = cjson.encode, decode = cjson.decode }
local function emit(src, name, ...)
    _G.source = src
    assert(events[name], 'missing event ' .. name)(...)
end
dofile('pm-devcoords/server/main.lua')
assert(commands.devcoords)
commands.devcoords(2)
assert(notices[#notices].args[1] == 'Administrator permission required.')
emit(2, 'pm-devcoords:create', 'Blocked', 'Row')
assert(not files['captures.json'])
emit(2, 'pm-devcoords:request')
assert(not files['captures.json'])
emit(1, 'pm-devcoords:create', 'Vineyard_01A', 'Row_01/SideA')
assert(files['captures.json'])
local point = { format='vector4', coords={x=1.2345,y=-2,z=3,h=90} }
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
local exported = assert(files['exports/Vineyard_01A.txt'])
assert(exported:find('Row_01',1,true))
assert(exported:find('SideA',1,true))
assert(exported:find('Point_01',1,true))
assert(exported:find('Point_02',1,true))
assert(exported:find('vector4(',1,true))
emit(1, 'pm-devcoords:undo', 'Vineyard_01A', 'Row_01/SideA')
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
assert(not files['exports/Vineyard_01A.txt']:find('Point_02',1,true))
local before = files['captures.json']
-- Reject invalid coordinates and names without changing persistent data.
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', {format='vector4',coords={x=0,y=0,z=0,h=math.huge}})
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', {format='bogus',coords={x=0,y=0,z=0,h=0}})
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', {format='vector4',coords={x=0,y=0,z=0}})
assert(files['captures.json'] == before)
failWrites = true
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
assert(files['captures.json'] == before)
failWrites = false
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
assert(not files['exports/Vineyard_01A.txt']:find('Point_02',1,true))
emit(1, 'pm-devcoords:create', '../invalid', 'x')
assert(not files['exports/invalid.lua'])
-- Verify generated export is syntactically valid Lua and retains point values.
vector3 = function(x,y,z) return {x=x,y=y,z=z} end
vector4 = function(x,y,z,h) return {x=x,y=y,z=z,h=h} end
local exportedCode = assert(files['exports/Vineyard_01A.txt'])
local chunk = assert(load(exportedCode, '@exported.txt', 't', {vector3=vector3,vector4=vector4}))
local decodedExport = chunk()
assert(decodedExport.Vineyard_01A.Row_01.SideA[1].coords.h == 90)
-- Simulate a server resource restart: reload from saved JSON.
events, commands = {}, {}
dofile('pm-devcoords/server/main.lua')
emit(1, 'pm-devcoords:request')
local latest = notices[#notices]
assert(latest.name == 'pm-devcoords:data')
assert(latest.args[1].Vineyard_01A['Row_01/SideA'][1].coords.x == 1.2345)
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
assert(files['exports/Vineyard_01A.txt']:find('Point_02',1,true))
print('PASS: ACE, create, capture, auto numbering, nested export, undo, failed write rollback, invalid names, text export content, JSON reload')
