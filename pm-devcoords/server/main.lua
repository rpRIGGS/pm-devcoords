local resource = GetCurrentResourceName()
local storage = 'captures.json'
local groups = {}

local function allowed(src)
    return src > 0 and IsPlayerAceAllowed(src, 'command.devcoords')
end

local function notify(src, message, kind)
    TriggerClientEvent('pm-devcoords:notify', src, message, kind or 'inform')
end

local function validName(name)
    return type(name) == 'string' and #name > 0 and #name <= 64
        and name:match('^[%w_%- ]+$') ~= nil
end

local function validCollection(name)
    if type(name) ~= 'string' or #name > 129 then return false end
    if validName(name) then return true end
    local parent, child = name:match('^([^/]+)/([^/]+)$')
    return parent ~= nil and validName(parent) and validName(child)
end

local function load()
    local raw = LoadResourceFile(resource, storage)
    if not raw or raw == '' then return end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == 'table' then groups = decoded end
end

local function persist()
    return SaveResourceFile(resource, storage, json.encode(groups), -1)
end

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

local function luaKey(name)
    return ('[%q]'):format(name)
end

local function exportGroup(name)
    local group = groups[name]
    if not group then return false end
    local lines = { 'return {', '    ' .. luaKey(name) .. ' = {' }
    local function appendPoints(points, indent)
        for _, point in ipairs(points) do
            local c = point.coords
            local coords = ('vector3(%.3f, %.3f, %.3f)'):format(c.x, c.y, c.z)
            if point.format == 'vector4' then
                coords = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x, c.y, c.z, c.h)
            end
            lines[#lines + 1] = indent .. ('{ name = %q, coords = %s },'):format(point.name, coords)
        end
    end

    local nested = {}
    for collection, points in pairs(group) do
        local parent, child = collection:match('^([^/]+)/([^/]+)$')
        if parent then
            nested[parent] = nested[parent] or { children = {}, points = nil }
            nested[parent].children[child] = points
        else
            nested[collection] = nested[collection] or { children = {}, points = nil }
            nested[collection].points = points
        end
    end
    for _, nameKey in ipairs(sortedKeys(nested)) do
        local entry = nested[nameKey]
        lines[#lines + 1] = '        ' .. luaKey(nameKey) .. ' = {'
        if entry.points then appendPoints(entry.points, '            ') end
        for _, child in ipairs(sortedKeys(entry.children)) do
            lines[#lines + 1] = '            ' .. luaKey(child) .. ' = {'
            appendPoints(entry.children[child], '                ')
            lines[#lines + 1] = '            },'
        end
        lines[#lines + 1] = '        },'
    end
    lines[#lines + 1] = '    },'
    lines[#lines + 1] = '}'
    local filename = '' .. name:gsub('[^%w_%-]', '_') .. '.txt'
    return SaveResourceFile(resource, filename, table.concat(lines, '\n') .. '\n', -1), filename
end

local function send(src)
    TriggerClientEvent('pm-devcoords:data', src, groups)
end

load()

RegisterCommand('devcoordscollector', function(src)
    if src == 0 then return end
    if not allowed(src) then return notify(src, 'Administrator permission required.', 'error') end
    TriggerClientEvent('pm-devcoords:toggle', src)
    send(src)
end, false)

RegisterNetEvent('pm-devcoords:request', function()
    local src = source
    if allowed(src) then send(src) end
end)

RegisterNetEvent('pm-devcoords:create', function(group, collection)
    local src = source
    if not allowed(src) then return end
    if not validName(group) or not validCollection(collection) then
        return notify(src, 'Invalid group or collection name.', 'error')
    end
    local createdGroup = groups[group] == nil
    if createdGroup then groups[group] = {} end
    local createdCollection = groups[group][collection] == nil
    if createdCollection then groups[group][collection] = {} end
    if not persist() then
        if createdCollection then groups[group][collection] = nil end
        if createdGroup then groups[group] = nil end
        return notify(src, 'Unable to save collection.', 'error')
    end
    send(src)
end)

RegisterNetEvent('pm-devcoords:capture', function(group, collection, point)
    local src = source
    if not allowed(src) then return end
    if not validName(group) or not validCollection(collection) or type(point) ~= 'table' then return end
    local list = groups[group] and groups[group][collection]
    if not list or #list >= 1000 then return end
    local c = point.coords
    if type(c) ~= 'table' or (point.format ~= 'vector3' and point.format ~= 'vector4') then return end
    for _, value in ipairs({ c.x, c.y, c.z, c.h }) do
        if type(value) ~= 'number' or value ~= value or math.abs(value) > 100000 then return end
    end
    if type(c.x) ~= 'number' or type(c.y) ~= 'number' or type(c.z) ~= 'number' or type(c.h) ~= 'number' then return end
    local name = validName(point.name) and point.name or ('Point_%02d'):format(#list + 1)
    list[#list + 1] = { name = name, format = point.format, coords = { x = c.x, y = c.y, z = c.z, h = c.h } }
    if not persist() then
        table.remove(list)
        return notify(src, 'Unable to save point.', 'error')
    end
    notify(src, name .. ' saved', 'success')
    send(src)
end)

RegisterNetEvent('pm-devcoords:undo', function(group, collection)
    local src = source
    if not allowed(src) or not validName(group) or not validCollection(collection) then return end
    local list = groups[group] and groups[group][collection]
    if not list or #list == 0 then return end
    local removed = table.remove(list)
    if not persist() then
        list[#list + 1] = removed
        return notify(src, 'Unable to undo point.', 'error')
    end
    notify(src, removed.name .. ' removed')
    send(src)
end)

RegisterNetEvent('pm-devcoords:export', function(group)
    local src = source
    if not allowed(src) or not validName(group) then return end
    local ok, filename = exportGroup(group)
    if ok then
        notify(src, 'Saved ' .. filename, 'success')
        TriggerClientEvent('pm-devcoords:exported', src, group, filename)
    else
        notify(src, 'Text export failed.', 'error')
    end
end)
