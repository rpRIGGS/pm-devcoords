local QBCore = exports['qb-core']:GetCoreObject()
local showCoords = false
local showVehicleInfo = false
local entityState = {aim=false,objects=false,vehicles=false,peds=false}
RegisterNetEvent('pm-devcoords:devadmin:entityStateChanged',function(state)
    if type(state)=='table' then entityState=state end
end)
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
        if showVehicleInfo then
                local car=GetVehiclePedIsIn(PlayerPedId(),false)
                if car~=0 and DoesEntityExist(car) and IsEntityAVehicle(car) then
                    local hash=GetEntityModel(car)
                    drawLabel(0.4,0.888,'Vehicle Developer Data')
                    drawLabel(0.4,0.913,('Entity: %s | Network: %s'):format(car,NetworkGetEntityIsNetworked(car) and NetworkGetNetworkIdFromEntity(car) or 'not networked'))
                    drawLabel(0.4,0.938,('Model: %s | Hash: %s'):format(GetLabelText(GetDisplayNameFromVehicleModel(hash)),hash))
                    drawLabel(0.4,0.963,('Engine: %.2f | Body: %.2f'):format(GetVehicleEngineHealth(car),GetVehicleBodyHealth(car)))
                end
            Wait(0)
        else Wait(300) end
    end
end)

RegisterNetEvent('pm-devcoords:devadmin:setmodel',function(name)
    local hash=joaat(name)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) or not IsModelAPed(hash) then return notify('Invalid ped model.','error') end
    lib.requestModel(hash)
    SetPlayerModel(PlayerId(),hash)
    SetModelAsNoLongerNeeded(hash)
    notify('Ped model changed to '..name,'success')
end)
RegisterNetEvent('pm-devcoords:devadmin:applyAmmo',function(weaponHash,amount)
    local ped=PlayerPedId()
    if type(amount)~='number' or amount<0 or amount>9999 then return end
    if weaponHash==joaat('WEAPON_UNARMED') or not HasPedGotWeapon(ped,weaponHash,false) then
        return notify('Weapon is not equipped or owned.','error')
    end
    SetPedAmmo(ped,weaponHash,amount)
    notify(('Weapon ammo set to %d.'):format(amount),'success')
end)
RegisterNetEvent('pm-devcoords:devadmin:requestAmmo',function(amount,weaponName)
    local weapon=weaponName and joaat(weaponName:upper()) or GetSelectedPedWeapon(PlayerPedId())
    if weapon==joaat('WEAPON_UNARMED') then return notify('Equip a weapon first.','error') end
    TriggerServerEvent('pm-devcoords:devadmin:setAmmo',weapon,amount)
end)
local function setAmmo()
    local ped=PlayerPedId()
    local weapon=GetSelectedPedWeapon(ped)
    if weapon==joaat('WEAPON_UNARMED') then return notify('Equip a weapon first.','error') end
    local current=GetAmmoInPedWeapon(ped,weapon)
    local result=lib.inputDialog('Set Weapon Ammo',{{type='number',label='Total ammunition',description='For your currently equipped weapon',default=current,min=0,max=9999,required=true}})
    if not result then return end
    local amount=tonumber(result[1])
    if not amount or amount%1~=0 or amount<0 or amount>9999 then return notify('Enter a whole number between 0 and 9999.','error') end
    TriggerServerEvent('pm-devcoords:devadmin:setAmmo',weapon,amount)
end

RegisterNetEvent('pm-devcoords:devadmin:setSpeed',function(speed)
    local ped=PlayerPedId()
    SetRunSprintMultiplierForPlayer(PlayerId(),speed)
    notify(('Run speed multiplier: %.2f'):format(speed),'success')
end)
RegisterNetEvent('pm-devcoords:devadmin:giveNuiFocus',function(state,cursor)
    SetNuiFocus(state,cursor)
    notify(state and 'NUI focus enabled. Use /givenuifocus off to release.' or 'NUI focus released.','inform')
end)

local open
local function statusOption(title,enabled,action,description)
    return {title=title,description=description,icon='power-off',iconColor=enabled and 'green' or 'red',onSelect=action}
end
local function entityStates()
    return entityState
end
local function openCoordinates()
    lib.registerContext({id='pm_devcoords_coordinates',title='Coordinates',menu='pm_devcoords_devadmin',options={
        {title='Coordinate collector',description='Pointer capture, groups, rows and text exports',onSelect=function() TriggerServerEvent('pm-devcoords:collector:toggle') end},
        {title='Copy vector2',icon='crosshairs',onSelect=function() ExecuteCommand('vector2') end},
        {title='Copy vector3',icon='crosshairs',onSelect=function() ExecuteCommand('vector3') end},
        {title='Copy vector4',icon='crosshairs',onSelect=function() ExecuteCommand('vector4') end},
        {title='Copy heading',icon='crosshairs',onSelect=function() ExecuteCommand('heading') end},
        statusOption('Toggle live coordinates',showCoords,function() TriggerEvent('pm-devcoords:devadmin:coords'); openCoordinates() end),
    }})
    lib.showContext('pm_devcoords_coordinates')
end
RegisterNetEvent('pm-devcoords:devadmin:coordinates',openCoordinates)
local openVehicles
local function openEntities()
    local state=entityStates()
    local function toggle(which)
        TriggerEvent('pm-devcoords:devadmin:entityview',which)
        openEntities()
    end
    lib.registerContext({id='pm_devcoords_entities',title='Entities',menu='pm_devcoords_devadmin',options={
        statusOption('Free aim viewer (E/G/H)',state.aim,function() toggle('aim') end),
        statusOption('Nearby objects',state.objects,function() toggle('objects') end),
        statusOption('Nearby vehicles',state.vehicles,function() toggle('vehicles') end),
        statusOption('Nearby peds',state.peds,function() toggle('peds') end),
        {title='Viewer distance',onSelect=function() TriggerEvent('pm-devcoords:devadmin:entityview','distance') end},
        {title='Copy aimed entity information',description='Aim at an entity; free aim viewer is not required',onSelect=function() TriggerEvent('pm-devcoords:devadmin:copyEntity') end},
    }})
    lib.showContext('pm_devcoords_entities')
end
openVehicles = function()
    lib.registerContext({id='pm_devcoords_vehicles',title='Vehicles',menu='pm_devcoords_devadmin',options={
        statusOption('Toggle vehicle developer HUD',showVehicleInfo,function() showVehicleInfo=not showVehicleInfo; openVehicles() end),
        {title='Max vehicle upgrades',icon='wrench',onSelect=function() ExecuteCommand('maxmods') end},
        {title='Save current vehicle (/admincar)',description='Add your vehicle to QBCore player_vehicles',onSelect=function() ExecuteCommand('admincar') end},
    }})
    lib.showContext('pm_devcoords_vehicles')
end
open = function()
    local function register(id, title, options)
        lib.registerContext({id=id, title=title, menu='pm_devcoords_devadmin', options=options})
        lib.showContext(id)
    end
    lib.registerContext({
        id='pm_devcoords_devadmin',
        title='PM DevCoords — Developer Tools',
        options={
            {title='Coordinates',description='Capture, copy and display coordinates',icon='crosshairs',onSelect=openCoordinates},
            {title='Entities',description='Inspect and manage aimed or nearby entities',icon='cube',onSelect=openEntities},
            {title='Vehicles',description='Vehicle data, upgrades and database saving',icon='car',onSelect=function() openVehicles() end},
            {title='Weapons',description='Set ammunition for your equipped weapon',icon='crosshair',onSelect=function()
                register('pm_devcoords_weapons','Weapons',{{title='Set Ammo',icon='crosshair',onSelect=setAmmo}})
            end},
            {title='Utilities',description='Waypoint teleport and ped model tools',icon='wrench',onSelect=function()
                register('pm_devcoords_utilities','Utilities',{
                    {title='Set run speed (/setspeed)',onSelect=function()
                        local v=lib.inputDialog('Run speed',{{type='number',label='Multiplier (1.0 normal, up to 1.49)',min=1,max=1.49,default=1.0,required=true}})
                        if v then ExecuteCommand('setspeed '..tostring(v[1])) end
                    end},
                    {title='Release NUI focus',description='Recover mouse and keyboard focus',onSelect=function() ExecuteCommand('givenuifocus off') end},
                    {title='Teleport to waypoint',description='Must set a waypoint on the map first',onSelect=waypoint},
                    {title='Set ped model',onSelect=function()
                        local v=lib.inputDialog('Developer ped model',{{type='input',label='Model name',required=true}})
                        if v then ExecuteCommand('setmodel '..v[1]) end
                    end},
                })
            end},
        }
    })
    lib.showContext('pm_devcoords_devadmin')
end
RegisterNetEvent('pm-devcoords:devadmin:open',open)

