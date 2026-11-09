local QBCore = exports['qb-core']:GetCoreObject()
local showCoords = false
local showVehicleInfo = false
local showEntityInfo = false
local showDevHud = false
local noclip = false
local noclipEntity = nil
local noclipSpeed = 1.5
local function drawLabel(x,y,value)
    SetTextFont(4); SetTextScale(0.35,0.35); SetTextColour(255,255,255,255)
    SetTextOutline(); SetTextEntry('STRING'); AddTextComponentString(value); DrawText(x,y)
end
local function notify(message, kind)
    lib.notify({title='PM DevCoords', description=message, type=kind or 'inform'})
end
local function vehicle()
    local ped = PlayerPedId()
    local car = GetVehiclePedIsIn(ped, false)
    if car == 0 then car = QBCore.Functions.GetClosestVehicle() end
    if car == 0 or not DoesEntityExist(car) then return nil end
    return car
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
local function spawnVehicle()
    local input = lib.inputDialog('Spawn developer vehicle', {{type='input',label='Vehicle model',required=true}})
    if not input or not input[1] then return end
    local model = input[1]:lower()
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return notify('Invalid vehicle model.', 'error') end
    lib.requestModel(hash)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local car = CreateVehicle(hash,c.x,c.y,c.z,h,true,false)
    if car == 0 then return notify('Could not spawn vehicle.', 'error') end
    SetEntityAsMissionEntity(car,true,true)
    SetVehicleOnGroundProperly(car)
    SetPedIntoVehicle(ped,car,-1)
    SetModelAsNoLongerNeeded(hash)
    notify('Spawned '..model,'success')
end
local function repair()
    local car = vehicle()
    if not car then return notify('No vehicle nearby.', 'error') end
    SetVehicleFixed(car); SetVehicleDeformationFixed(car); SetVehicleDirtLevel(car,0.0)
    notify('Vehicle repaired.', 'success')
end
local function deleteVehicle()
    local car = vehicle()
    if not car then return notify('No vehicle nearby.', 'error') end
    NetworkRequestControlOfEntity(car)
    local deadline = GetGameTimer()+1500
    while not NetworkHasControlOfEntity(car) and GetGameTimer()<deadline do Wait(0); NetworkRequestControlOfEntity(car) end
    if not NetworkHasControlOfEntity(car) then return notify('Could not obtain vehicle control.', 'error') end
    SetEntityAsMissionEntity(car,true,true); DeleteVehicle(car)
    notify('Vehicle delete requested.')
end
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
local function toggleNoClip()
    local ped = PlayerPedId()
    noclip = not noclip
    if noclip then
        noclipEntity = GetVehiclePedIsIn(ped,false)
        if noclipEntity == 0 then noclipEntity = ped end
        FreezeEntityPosition(noclipEntity,true)
        SetEntityCollision(noclipEntity,false,false)
        SetEntityInvincible(noclipEntity,true)
    else
        local entity = noclipEntity
        if entity and DoesEntityExist(entity) then
            FreezeEntityPosition(entity,false)
            SetEntityCollision(entity,true,true)
            SetEntityInvincible(entity,false)
        end
        noclipEntity = nil
    end
    notify('NoClip '..(noclip and 'enabled' or 'disabled'))
end
CreateThread(function()
    while true do
        if noclip and noclipEntity and DoesEntityExist(noclipEntity) then
            local entity=noclipEntity
            local rot=GetGameplayCamRot(2)
            local pitch=math.rad(rot.x)
            local yaw=math.rad(rot.z)
            local forward=vector3(-math.sin(yaw)*math.cos(pitch),math.cos(yaw)*math.cos(pitch),math.sin(pitch))
            local right=vector3(math.cos(yaw),math.sin(yaw),0.0)
            local delta=vector3(0.0,0.0,0.0)
            if IsControlPressed(0,32) then delta=delta+forward end
            if IsControlPressed(0,33) then delta=delta-forward end
            if IsControlPressed(0,35) then delta=delta+right end
            if IsControlPressed(0,34) then delta=delta-right end
            if IsControlPressed(0,22) then delta=delta+vector3(0,0,1) end
            if IsControlPressed(0,36) then delta=delta-vector3(0,0,1) end
            local speed=noclipSpeed*(IsControlPressed(0,21) and 4.0 or 1.0)
            local coords=GetEntityCoords(entity)
            SetEntityCoordsNoOffset(entity,coords.x+delta.x*speed,coords.y+delta.y*speed,coords.z+delta.z*speed,false,false,false)
            SetEntityHeading(entity,(-rot.z)%360.0)
            Wait(0)
        else Wait(300) end
    end
end)
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
