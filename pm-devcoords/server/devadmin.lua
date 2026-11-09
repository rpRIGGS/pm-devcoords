local QBCore = exports['qb-core']:GetCoreObject()
local function permitted(src)
    return src > 0 and (IsPlayerAceAllowed(src, 'command.devcoords') or QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god'))
end
local function tell(src, message, kind)
    TriggerClientEvent('pm-devcoords:notify', src, message, kind or 'inform')
end
RegisterCommand('devadmin', function(src)
    if not permitted(src) then return tell(src, 'Developer permission required.', 'error') end
    TriggerClientEvent('pm-devcoords:devadmin:open', src)
end, false)
for _, command in ipairs({'vector2','vector3','vector4','heading'}) do
    RegisterCommand(command, function(src)
        if not permitted(src) then return tell(src, 'Developer permission required.', 'error') end
        TriggerClientEvent('pm-devcoords:devadmin:copy', src, command)
    end, false)
end
RegisterCommand('coords', function(src)
    if not permitted(src) then return tell(src, 'Developer permission required.', 'error') end
    TriggerClientEvent('pm-devcoords:devadmin:coords', src)
end, false)
RegisterCommand('admincar', function(src)
    if not permitted(src) then return tell(src, 'Developer permission required.', 'error') end
    TriggerClientEvent('pm-devcoords:devadmin:admincar', src)
end, false)
RegisterNetEvent('pm-devcoords:devadmin:savecar', function(props)
    local src = source
    if not permitted(src) then return end
    if type(props) ~= 'table' or type(props.model) ~= 'number' or type(props.plate) ~= 'string' then return end
    local ped = GetPlayerPed(src)
    local driven = GetVehiclePedIsIn(ped, false)
    if driven == 0 or GetPedInVehicleSeat(driven, -1) ~= ped then return tell(src, 'You must be driving the vehicle.', 'error') end
    local currentPlate = GetVehicleNumberPlateText(driven):gsub('^%s+', ''):gsub('%s+$', '')
    local submittedPlate = props.plate:gsub('^%s+', ''):gsub('%s+$', '')
    if GetEntityModel(driven) ~= props.model or currentPlate ~= submittedPlate then
        return tell(src, 'Vehicle details do not match the driven vehicle.', 'error')
    end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local vehicleName
    for name, definition in pairs(QBCore.Shared.Vehicles or {}) do
        if type(definition) == 'table' and GetHashKey(name) == props.model then
            vehicleName = name
            break
        end
    end
    if not vehicleName then return tell(src, 'Vehicle model not in QBCore shared vehicles.', 'error') end
    local plate = props.plate:match('^%s*(.-)%s*$')
    if plate == '' or #plate > 8 then return tell(src, 'Invalid plate.', 'error') end
    if not MySQL or not MySQL.query or not MySQL.insert then
        return tell(src, 'oxmysql is required to save admin vehicles.', 'error')
    end
    local ok, result = pcall(function()
        local existing = MySQL.query.await('SELECT plate FROM player_vehicles WHERE plate = ? LIMIT 1', {plate})
        if existing and #existing > 0 then return false end
        return MySQL.insert.await('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            player.PlayerData.license, player.PlayerData.citizenid, vehicleName, tostring(props.model), json.encode(props), plate, 0
        })
    end)
    if not ok or not result then return tell(src, 'Vehicle save failed or plate already exists.', 'error') end
    tell(src, 'Vehicle saved to player_vehicles: '..plate, 'success')
end)
