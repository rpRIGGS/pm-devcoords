local resource = GetCurrentResourceName()
local storage = 'captures.json'
local groups = {}

local function allowed(src)
    return src > 0 and IsPlayerAceAllowed(src, 'command.devcoords')
end

local function notify(src, message, kind)
    TriggerClientEvent('pm-devcoords:notify', src, message, kind or 'inform')
end

local function validName(value)
    return type(value) == 'string' and #value > 0 and #value <= 64 and value:match('^[%w_%- ]+$') ~= nil
end

local function validCollection(value)
    if type(value) ~= 'string' or #value > 129 then return false end
    local first, second = value:match('^([^/]+)/([^/]+)
    local raw = LoadResourceFile(resource, storage)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then groups = decoded end
    end
end

local function persist()
    return SaveResourceFile(resource, storage, json.encode(groups), -1)
end

local function luaKey(name)
    return ('[%q]'):format(name)
end

local function exportGroup(name)
    local group = groups[name]
    if not group then return false end
    local lines = { 'return {', '    ' .. luaKey(name) .. ' = {' }
    local function sortedKeys(tbl)
        local keys = {}
        for key in pairs(tbl) do keys[#keys + 1] = key end
        table.sort(keys)
        return keys
    end
    local function appendPoints(list, indent)
        for _, point in ipairs(list) do
            local c = point.coords
            local value = ('vector3(%.3f, %.3f, %.3f)'):format(c.x, c.y, c.z)
            if point.format == 'vector4' then
                value = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x, c.y, c.z, c.h)
            end
            lines[#lines + 1] = indent .. ('{ name = %q, coords = %s },'):format(point.name, value)
        end
    end
    local nested = {}
    for collectionName, list in pairs(group) do
        local parent, child = collectionName:match('^([^/]+)/([^/]+)$')
        if parent then
            nested[parent] = nested[parent] or {}
            nested[parent][child] = list
        else
            nested[collectionName] = list
        end
    end
    for _, name in ipairs(sortedKeys(nested)) do
        local value = nested[name]
        lines[#lines + 1] = '        ' .. luaKey(name) .. ' = {'
        if #value > 0 then
            appendPoints(value, '            ')
        else
            for _, child in ipairs(sortedKeys(value)) do
                lines[#lines + 1] = '            ' .. luaKey(child) .. ' = {'
                appendPoints(value[child], '                ')
                lines[#lines + 1] = '            },'
            end
        end
        lines[#lines + 1] = '        },'
    end
    lines[#lines + 1] = '    },'
    lines[#lines + 1] = '}'
    local safe = name:gsub('[^%w_%-]', '_')
    return SaveResourceFile(resource, 'exports/' .. safe .. '.lua', table.concat(lines, '\n') .. '\n', -1)
end

local function send(src)
    TriggerClientEvent('pm-devcoords:data', src, groups)
end

load()

RegisterCommand('devcoords', function(src)
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
    if not validName(group) or not validCollection(collection) then return notify(src, 'Use names up to 64 letters, numbers, spaces, hyphens or underscores.', 'error') end
    groups[group] = groups[group] or {}
    groups[group][collection] = groups[group][collection] or {}
    if not persist() then return notify(src, 'Unable to save captures.', 'error') end
    send(src)
end)

RegisterNetEvent('pm-devcoords:capture', function(group, collection, point)
    local src = source
    if not allowed(src) then return end
    if not validName(group) or not validCollection(collection) or type(point) ~= 'table' then return end
    local list = groups[group] and groups[group][collection]
    if not list or #list >= 1000 then return end
    local c = point.coords
    if type(c) ~= 'table' or type(point.format) ~= 'string' or (point.format ~= 'vector3' and point.format ~= 'vector4') then return end
    if not c.x or not c.y or not c.z or not c.h then return end
    for _, n in ipairs({ c.x, c.y, c.z, c.h }) do
        if type(n) ~= 'number' or n ~= n or math.abs(n) > 100000 then return end
    end
    local name = validName(point.name) and point.name or ('Point_%02d'):format(#list + 1)
    list[#list + 1] = { name = name, format = point.format, coords = { x = c.x, y = c.y, z = c.z, h = c.h } }
    if not persist() then table.remove(list) return notify(src, 'Save failed.', 'error') end
    notify(src, name .. ' saved to ' .. collection, 'success')
    send(src)
end)

RegisterNetEvent('pm-devcoords:undo', function(group, collection)
    local src = source
    if not allowed(src) then return end
    local list = type(group) == 'string' and groups[group] and groups[group][collection]
    if not list or #list == 0 then return end
    local removed = table.remove(list)
    if not persist() then list[#list + 1] = removed return notify(src, 'Save failed.', 'error') end
    notify(src, removed.name .. ' removed')
    send(src)
end)

RegisterNetEvent('pm-devcoords:export', function(group)
    local src = source
    if not allowed(src) or not validName(group) then return end
    if exportGroup(group) then
        notify(src, 'Saved exports/' .. group:gsub('[^%w_%-]', '_') .. '.lua', 'success')
    else
        notify(src, 'Export failed. Ensure the exports folder exists.', 'error')
    end
end)
)
    return validName(value) or (first and validName(first) and validName(second)) or false
end

local function load()
    local raw = LoadResourceFile(resource, storage)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then groups = decoded end
    end
end

local function persist()
    return SaveResourceFile(resource, storage, json.encode(groups), -1)
end

local function luaKey(name)
    return ('[%q]'):format(name)
end

local function exportGroup(name)
    local group = groups[name]
    if not group then return false end
    local lines = { 'return {', '    ' .. luaKey(name) .. ' = {' }
    local function sortedKeys(tbl)
        local keys = {}
        for key in pairs(tbl) do keys[#keys + 1] = key end
        table.sort(keys)
        return keys
    end
    for _, collectionName in ipairs(sortedKeys(group)) do
        lines[#lines + 1] = '        ' .. luaKey(collectionName) .. ' = {'
        for _, point in ipairs(group[collectionName]) do
            local c = point.coords
            local value = ('vector3(%.3f, %.3f, %.3f)'):format(c.x, c.y, c.z)
            if point.format == 'vector4' then
                value = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x, c.y, c.z, c.h)
            end
            lines[#lines + 1] = ('            { name = %q, coords = %s },'):format(point.name, value)
        end
        lines[#lines + 1] = '        },'
    end
    lines[#lines + 1] = '    },'
    lines[#lines + 1] = '}'
    local safe = name:gsub('[^%w_%-]', '_')
    return SaveResourceFile(resource, 'exports/' .. safe .. '.lua', table.concat(lines, '\n') .. '\n', -1)
end

local function send(src)
    TriggerClientEvent('pm-devcoords:data', src, groups)
end

load()

RegisterCommand('devcoords', function(src)
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
    if not validName(group) or not validName(collection) then return notify(src, 'Use names up to 64 letters, numbers, spaces, hyphens or underscores.', 'error') end
    groups[group] = groups[group] or {}
    groups[group][collection] = groups[group][collection] or {}
    if not persist() then return notify(src, 'Unable to save captures.', 'error') end
    send(src)
end)

RegisterNetEvent('pm-devcoords:capture', function(group, collection, point)
    local src = source
    if not allowed(src) then return end
    if not validName(group) or not validName(collection) or type(point) ~= 'table' then return end
    local list = groups[group] and groups[group][collection]
    if not list or #list >= 1000 then return end
    local c = point.coords
    if type(c) ~= 'table' or type(point.format) ~= 'string' or (point.format ~= 'vector3' and point.format ~= 'vector4') then return end
    if not c.x or not c.y or not c.z or not c.h then return end
    for _, n in ipairs({ c.x, c.y, c.z, c.h }) do
        if type(n) ~= 'number' or n ~= n or math.abs(n) > 100000 then return end
    end
    local name = validName(point.name) and point.name or ('Point_%02d'):format(#list + 1)
    list[#list + 1] = { name = name, format = point.format, coords = { x = c.x, y = c.y, z = c.z, h = c.h } }
    if not persist() then table.remove(list) return notify(src, 'Save failed.', 'error') end
    notify(src, name .. ' saved to ' .. collection, 'success')
    send(src)
end)

RegisterNetEvent('pm-devcoords:undo', function(group, collection)
    local src = source
    if not allowed(src) then return end
    local list = type(group) == 'string' and groups[group] and groups[group][collection]
    if not list or #list == 0 then return end
    local removed = table.remove(list)
    if not persist() then list[#list + 1] = removed return notify(src, 'Save failed.', 'error') end
    notify(src, removed.name .. ' removed')
    send(src)
end)

RegisterNetEvent('pm-devcoords:export', function(group)
    local src = source
    if not allowed(src) or not validName(group) then return end
    if exportGroup(group) then
        notify(src, 'Saved exports/' .. group:gsub('[^%w_%-]', '_') .. '.lua', 'success')
    else
        notify(src, 'Export failed. Ensure the exports folder exists.', 'error')
    end
end)
