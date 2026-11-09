local QBCore = exports['qb-core']:GetCoreObject()
local showCoords = false
local showVehicleInfo = false
local showDevHud = false
local function drawLabel(x,y,value)
    SetTextFont(4); SetTextScale(0.35,0.35); SetTextColour(255,255,255,255)
    SetTextOutline(); SetTextEntry('STRING'); AddTextComponentString(value); DrawText(x,y)
end
local function notify(message, kind)
    lib.notify({title='PM DevCoords', description=message, type=kind or 'inform'})
end
local function copy(kind)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local result
    if kind == 'vector2' then result = ('vector2(%.2f, %.2f)'):format(c.x,c.y)
    elseif kind == 'vector3' then result = ('vector3(%.2f, %.2f, %.2f)'):format(c.x,c.y,c.z)
    elseif kind == 'vector4' then result = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(c.x,c.y,c.z,h)
    elseif kind == 'heading' then result = ('%.2f'):format(h) end
    if result then lib.setClipboard(result); notify('Copied '..kind..': '..result, 'success') end
end
RegisterNetEvent('pm-devcoords:devadmin:copy', copy)
RegisterNetEvent('pm-devcoords:devadmin:coords', function()
    showCoords = not showCoords
    notify('Coordinate display '..(showCoords and 'enabled' or 'disabled'))
end)
CreateThread(function()
    while true do
        if showCoords then
            local c = GetEntityCoords(PlayerPedId())
            local h = GetEntityHeading(PlayerPedId())
            drawLabel(0.4,0.025,('vector4(%.2f, %.2f, %.2f, %.2f)'):format(c.x,c.y,c.z,h))
            Wait(0)
        else Wait(400) end
    end
end)
RegisterNetEvent('pm-devcoords:devadmin:admincar', function()
    local car = GetVehiclePedIsIn(PlayerPedId(),false)
    if car == 0 or GetPedInVehicleSeat(car,-1) ~= PlayerPedId() then
        return notify('Sit in the driver seat of the vehicle to save.', 'error')
    end
    TriggerServerEvent('pm-devcoords:devadmin:savecar', QBCore.Functions.GetVehicleProperties(car))
end)
local function maxVehicle()
    local car = GetVehiclePedIsIn(PlayerPedId(), false)
    if car == 0 then return notify('Enter a vehicle to apply max performance upgrades.', 'error') end
    if GetPedInVehicleSeat(car, -1) ~= PlayerPedId() then return notify('You must be the driver.', 'error') end
    SetVehicleModKit(car, 0)
    -- Original qb-adminmenu performance upgrade slots (not every cosmetic mod).
    for _, slot in ipairs({11, 12, 13, 15, 16}) do
        local highest = GetNumVehicleMods(car, slot) - 1
        if highest >= 0 then SetVehicleMod(car, slot, highest, false) end
    end
    ToggleVehicleMod(car, 18, true)
    SetVehicleFixed(car)
    notify('Maximum performance upgrades applied.', 'success')
end
RegisterNetEvent('pm-devcoords:devadmin:maxmods', maxVehicle)
local function waypoint()
    local blip=GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then return notify('Set a waypoint first.','error') end
    local c=GetBlipInfoIdCoord(blip)
    local ped=PlayerPedId()
    local entity=GetVehiclePedIsIn(ped,false)
    if entity==0 then entity=ped end
    for height=1,1000,50 do
        SetEntityCoordsNoOffset(entity,c.x,c.y,height+0.0,false,false,false)
        Wait(0)
        local found,z=GetGroundZFor_3dCoord(c.x,c.y,height+0.0,false)
        if found then
            SetEntityCoordsNoOffset(entity,c.x,c.y,z+1.0,false,false,false)
            notify('Teleported to waypoint.','success')
            return
        end
    end
    SetEntityCoordsNoOffset(entity,c.x,c.y,1000.0,false,false,false)
    notify('Ground height unavailable; teleported above waypoint.','error')
end
CreateThread(function()
    while true do
        if showVehicleInfo or showDevHud then
            if showVehicleInfo then
                local car=GetVehiclePedIsIn(PlayerPedId(),false)
                if car~=0 then
                    local hash=GetEntityModel(car)
                    drawLabel(0.4,0.888,'Vehicle Developer Data')
                    drawLabel(0.4,0.913,('Entity: %s | Network: %s'):format(car,NetworkGetNetworkIdFromEntity(car)))
                    drawLabel(0.4,0.938,('Model: %s | Hash: %s'):format(GetLabelText(GetDisplayNameFromVehicleModel(hash)),hash))
                    drawLabel(0.4,0.963,('Engine: %.2f | Body: %.2f'):format(GetVehicleEngineHealth(car),GetVehicleBodyHealth(car)))
                end
            end
            if showDevHud then drawLabel(0.015,0.05,'Developer HUD enabled') end
            Wait(0)
        else Wait(300) end
    end
end)
local function open()
    local options={
        {title='Coordinate collector',description='Open the existing pointer and group capture tool',onSelect=function() ExecuteCommand('devcoords') end},
        {title='Copy vector2',onSelect=function() ExecuteCommand('vector2') end},
        {title='Copy vector3',onSelect=function() ExecuteCommand('vector3') end},
        {title='Copy vector4',onSelect=function() ExecuteCommand('vector4') end},
        {title='Copy heading',onSelect=function() ExecuteCommand('heading') end},
        {title='Toggle live coordinates',onSelect=function() ExecuteCommand('coords') end},

        {title='Toggle vehicle developer HUD',onSelect=function() showVehicleInfo=not showVehicleInfo end},
        {title='Entity viewer: free aim (E/G/H)',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','aim') end},
        {title='Entity viewer: nearby objects',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','objects') end},
        {title='Entity viewer: nearby vehicles',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','vehicles') end},
        {title='Entity viewer: nearby peds',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','peds') end},
        {title='Entity viewer: distance',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','distance') end},
        {title='Copy full aimed entity information',onSelect=function() TriggerEvent('pm-devcoords:devadmin:copyEntity') end},
        {title='Toggle HUD developer mode',onSelect=function()
            showDevHud=not showDevHud
            SetPlayerInvincible(PlayerId(),showDevHud)
            notify('Developer HUD '..(showDevHud and 'enabled' or 'disabled'))
        end},
        {title='Max vehicle upgrades',onSelect=maxVehicle},
        {title='Save vehicle (/admincar)',description='Add your current QBCore vehicle to player_vehicles',onSelect=function() ExecuteCommand('admincar') end},
        {title='Teleport to waypoint',onSelect=waypoint},
    }
    lib.registerContext({id='pm_devcoords_devadmin',title='PowerMoves Developer Tools',options=options})
    lib.showContext('pm_devcoords_devadmin')
end
RegisterNetEvent('pm-devcoords:devadmin:open',open)
