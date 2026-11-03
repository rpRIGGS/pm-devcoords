-- Runs against real server/main.lua with mocked FiveM APIs.
local commands, events, files, notices = {}, {}, {}, {}
local currentSource = 1
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
local function encode(v)
    if type(v) == 'table' then
        local n, entries = #v, {}
        if n > 0 then
            for i=1,n do entries[#entries+1] = encode(v[i]) end
            return '[' .. table.concat(entries, ',') .. ']'
        end
        for k, value in pairs(v) do
            entries[#entries+1] = string.format('%q:%s', k, encode(value))
        end
        return '{' .. table.concat(entries, ',') .. '}'
    end
    if type(v) == 'string' then return string.format('%q', v) end
    return tostring(v)
end
json = { encode = encode, decode = function() return {} end }
local function emit(src, name, ...)
    currentSource = src
    _G.source = src
    assert(events[name], 'missing event ' .. name)(...)
end
dofile('pm-devcoords/server/main.lua')
assert(commands.devcoords)
commands.devcoords(2)
assert(notices[#notices].args[1] == 'Administrator permission required.')
emit(2, 'pm-devcoords:create', 'Blocked', 'Row')
assert(not files['captures.json'])
emit(1, 'pm-devcoords:create', 'Vineyard_01A', 'Row_01/SideA')
assert(files['captures.json'])
local point = { format='vector4', coords={x=1.2345,y=-2,z=3,h=90} }
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
local exported = assert(files['exports/Vineyard_01A.lua'])
assert(exported:find('Row_01',1,true))
assert(exported:find('SideA',1,true))
assert(exported:find('Point_01',1,true))
assert(exported:find('Point_02',1,true))
assert(exported:find('vector4(1.234',1,true))
emit(1, 'pm-devcoords:undo', 'Vineyard_01A', 'Row_01/SideA')
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
assert(not files['exports/Vineyard_01A.lua']:find('Point_02',1,true))
local before = files['captures.json']
failWrites = true
emit(1, 'pm-devcoords:capture', 'Vineyard_01A', 'Row_01/SideA', point)
assert(files['captures.json'] == before)
failWrites = false
emit(1, 'pm-devcoords:export', 'Vineyard_01A')
assert(not files['exports/Vineyard_01A.lua']:find('Point_02',1,true))
emit(1, 'pm-devcoords:create', '../invalid', 'x')
assert(not files['exports/invalid.lua'])
print('PASS: ACE, create, capture, auto numbering, nested export, undo, failed write rollback, invalid names')
