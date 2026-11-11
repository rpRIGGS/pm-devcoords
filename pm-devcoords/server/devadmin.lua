local QBCore = exports['qb-core']:GetCoreObject()
local function permitted(src)
    return src > 0 and (QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god'))
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
RegisterCommand('maxmods', function(src)
    if not permitted(src) then return tell(src, 'Developer permission required.', 'error') end
    TriggerClientEvent('pm-devcoords:devadmin:maxmods', src)
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
        if type(definition) == 'table' then
            local model = definition.model or name
            local hash = type(model) == 'number' and model or (type(model) == 'string' and GetHashKey(model))
            if hash == props.model or tonumber(definition.hash) == props.model then
                vehicleName = type(model) == 'string' and model or name
                break
            end
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

RegisterCommand('setmodel', function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local model=args[1]
    if not model or model=='' then return tell(src,'Usage: /setmodel model [player id]','error') end
    local target=tonumber(args[2]) or src
    if not QBCore.Functions.GetPlayer(target) then return tell(src,'Player not online.','error') end
    TriggerClientEvent('pm-devcoords:devadmin:setmodel',target,model)
end,false)

-- QBCore weapon ammo is also stored in the weapon item's info.ammo.
RegisterNetEvent('pm-devcoords:devadmin:setAmmo',function(weaponHash,amount)
    local src=source
    if not permitted(src) then return end
    if type(weaponHash)~='number' or type(amount)~='number' or amount%1~=0 or amount<0 or amount>9999 then return end
    local player=QBCore.Functions.GetPlayer(src)
    if not player then return end
    local items=player.PlayerData.items or {}
    local matched=false
    for slot,item in pairs(items) do
        if item and type(item.name)=='string' and item.name:sub(1,7)=='weapon_' and GetHashKey(item.name)==weaponHash then
            item.info=type(item.info)=='table' and item.info or {}
            item.info.ammo=amount
            items[slot]=item
            matched=true
            break
        end
    end
    if not matched then return tell(src,'Equipped weapon not found in QBCore inventory.','error') end
    player.Functions.SetInventory(items)
    TriggerClientEvent('pm-devcoords:devadmin:applyAmmo',src,weaponHash,amount)
end)

-- Developer ammo and utility commands.
RegisterCommand('setammo',function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local amount=tonumber(args[1])
    if not amount or amount%1~=0 or amount>9999 or amount<0 then return tell(src,'Usage: /setammo [0-9999]','error') end
    local weapon=args[2]
    if weapon and not weapon:upper():match('^WEAPON_[%w_]+

RegisterCommand('setspeed',function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local speed=(args[1] or 'normal'):lower()
    local value
    if speed=='normal' then value=1.0
    elseif speed=='fast' then value=1.49
    else value=tonumber(speed) end
    if not value or value<1.0 or value>1.49 then return tell(src,'Usage: /setspeed [fast|normal|1.0-1.49]','error') end
    TriggerClientEvent('pm-devcoords:devadmin:setSpeed',src,value)
end,false)

RegisterCommand('givenuifocus',function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local target=tonumber(args[1]) or src
    local offset=tonumber(args[1]) and 2 or 1
    local function parse(v)
        if v=='on' or v=='true' or v=='1' then return true end
        if v=='off' or v=='false' or v=='0' then return false end
    end
    local focus=parse((args[offset] or ''):lower())
    local cursor=parse((args[offset+1] or args[offset] or ''):lower())
    if focus==nil or cursor==nil then return tell(src,'Usage: /givenuifocus [id] [true/false] [true/false]','error') end
    if not QBCore.Functions.GetPlayer(target) then return tell(src,'Player not online.','error') end
    TriggerClientEvent('pm-devcoords:devadmin:giveNuiFocus',target,focus,cursor)
end,false)
) then weapon='WEAPON_'..weapon end
    TriggerClientEvent('pm-devcoords:devadmin:requestAmmo',src,amount,weapon)
end,false)

RegisterCommand('setspeed',function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local speed=(args[1] or 'normal'):lower()
    local value
    if speed=='normal' then value=1.0
    elseif speed=='fast' then value=1.49
    else value=tonumber(speed) end
    if not value or value<1.0 or value>1.49 then return tell(src,'Usage: /setspeed [fast|normal|1.0-1.49]','error') end
    TriggerClientEvent('pm-devcoords:devadmin:setSpeed',src,value)
end,false)

RegisterCommand('givenuifocus',function(src,args)
    if not permitted(src) then return tell(src,'Developer permission required.','error') end
    local target=tonumber(args[1]) or src
    local offset=tonumber(args[1]) and 2 or 1
    local function parse(v)
        if v=='on' or v=='true' or v=='1' then return true end
        if v=='off' or v=='false' or v=='0' then return false end
    end
    local focus=parse((args[offset] or ''):lower())
    local cursor=parse((args[offset+1] or args[offset] or ''):lower())
    if focus==nil or cursor==nil then return tell(src,'Usage: /givenuifocus [id] [true/false] [true/false]','error') end
    if not QBCore.Functions.GetPlayer(target) then return tell(src,'Player not online.','error') end
    TriggerClientEvent('pm-devcoords:devadmin:giveNuiFocus',target,focus,cursor)
end,false)

