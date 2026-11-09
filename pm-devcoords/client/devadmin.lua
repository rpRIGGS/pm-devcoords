local QBCore = exports['qb-core']:GetCoreObject()
local showCoords = false
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
    if kind == 'vector2' then result = ('vector2(%.3f, %.3f)'):format(c.x,c.y)
    elseif kind == 'vector3' then result = ('vector3(%.3f, %.3f, %.3f)'):format(c.x,c.y,c.z)
    elseif kind == 'vector4' then result = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x,c.y,c.z,h)
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
            SetTextFont(4); SetTextScale(0.35,0.35); SetTextColour(255,255,255,255)
            SetTextOutline(); SetTextEntry('STRING')
            AddTextComponentString(('X %.3f | Y %.3f | Z %.3f | H %.2f'):format(c.x,c.y,c.z,h))
            DrawText(0.015,0.78)
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
    local car = vehicle()
    if not car then return notify('No vehicle nearby.', 'error') end
    SetVehicleModKit(car,0)
    for slot=0,49 do
        local max=GetNumVehicleMods(car,slot)-1
        if max>=0 then SetVehicleMod(car,slot,max,false) end
    end
    ToggleVehicleMod(car,18,true)
    SetVehicleFixed(car)
    notify('Vehicle upgrades applied.','success')
end
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
local function open()
    local options={
        {title='Coordinate collector',description='Open the existing pointer and group capture tool',onSelect=function() ExecuteCommand('devcoords') end},
        {title='Copy vector2',onSelect=function() ExecuteCommand('vector2') end},
        {title='Copy vector3',onSelect=function() ExecuteCommand('vector3') end},
        {title='Copy vector4',onSelect=function() ExecuteCommand('vector4') end},
        {title='Copy heading',onSelect=function() ExecuteCommand('heading') end},
        {title='Toggle live coordinates',onSelect=function() ExecuteCommand('coords') end},
        {title='Spawn vehicle',onSelect=spawnVehicle},
        {title='Repair vehicle',onSelect=repair},
        {title='Delete vehicle',onSelect=deleteVehicle},
        {title='Max vehicle upgrades',onSelect=maxVehicle},
        {title='Save vehicle (/admincar)',description='Add your current QBCore vehicle to player_vehicles',onSelect=function() ExecuteCommand('admincar') end},
        {title='Teleport to waypoint',onSelect=waypoint},
    }
    lib.registerContext({id='pm_devcoords_devadmin',title='PowerMoves Developer Tools',options=options})
    lib.showContext('pm_devcoords_devadmin')
end
RegisterNetEvent('pm-devcoords:devadmin:open',open)
