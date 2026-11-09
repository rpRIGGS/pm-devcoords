local enabled = false
local showObjects, showVehicles, showPeds = false, false, false
local maxDistance = 12.0
local frozen = {}
local function notify(message, kind)
    lib.notify({title='PM DevCoords',description=message,type=kind or 'inform'})
end
local function label(x,y,s)
    SetTextFont(4); SetTextScale(0.32,0.32); SetTextColour(255,255,255,240)
    SetTextOutline(); SetTextEntry('STRING'); AddTextComponentString(s); DrawText(x,y)
end
local function aimed()
    local origin,rot = GetGameplayCamCoord(),GetGameplayCamRot(2)
    local pitch,yaw = math.rad(rot.x),math.rad(rot.z)
    local direction=vector3(-math.sin(yaw)*math.cos(pitch),math.cos(yaw)*math.cos(pitch),math.sin(pitch))
    local dest=origin+direction*1000.0
    local handle=StartExpensiveSynchronousShapeTestLosProbe(origin.x,origin.y,origin.z,dest.x,dest.y,dest.z,-1,PlayerPedId(),7)
    local _,hit,pos,_,entity=GetShapeTestResult(handle)
    return hit==1,pos,entity
end
local function copyCoords(pos)
    lib.setClipboard(('vector3(%.3f, %.3f, %.3f)'):format(pos.x,pos.y,pos.z))
    notify('Aimed coordinates copied to clipboard.','success')
end
local function entityName(entity)
    local hash = GetEntityModel(entity)
    if IsEntityAVehicle(entity) then return GetDisplayNameFromVehicleModel(hash) end
    return tostring(hash)
end
local function entityDetails(entity)
    local c=GetEntityCoords(entity)
    local r=GetEntityRotation(entity,2)
    local v=GetEntityVelocity(entity)
    local kind=GetEntityType(entity)
    local networked=NetworkGetEntityIsNetworked(entity)
    local net=networked and tostring(NetworkGetNetworkIdFromEntity(entity)) or 'not networked'
    local owner=networked and tostring(GetPlayerServerId(NetworkGetEntityOwner(entity))) or 'local'
    local lines={
        ('Model: %s | Hash: %s'):format(entityName(entity),GetEntityModel(entity)),
        ('Type: %s | Entity: %s | Net ID: %s | Owner: %s'):format(kind,entity,net,owner),
        ('Distance: %.2f | Heading: %.2f'):format(#(GetEntityCoords(PlayerPedId())-c),GetEntityHeading(entity)),
        ('Coords: vector3(%.2f, %.2f, %.2f)'):format(c.x,c.y,c.z),
        ('Rotation: vector3(%.2f, %.2f, %.2f)'):format(r.x,r.y,r.z),
        ('Velocity: vector3(%.2f, %.2f, %.2f)'):format(v.x,v.y,v.z)
    }
    if kind==1 then
        lines[#lines+1]=('Health: %s | Max health: %s | Armour: %s'):format(GetEntityHealth(entity),GetPedMaxHealth(entity),GetPedArmour(entity))
        lines[#lines+1]=('Relationship group: %s | Relationship to player: %s'):format(GetPedRelationshipGroupHash(entity),GetRelationshipBetweenPeds(entity,PlayerPedId()))
    elseif kind==2 then
        lines[#lines+1]=('RPM: %.2f | Speed MPH: %.0f | Gear: %s'):format(GetVehicleCurrentRpm(entity),GetEntitySpeed(entity)*2.23694,GetVehicleCurrentGear(entity))
        lines[#lines+1]=('Acceleration: %.2f | Engine: %.1f | Body: %.1f'):format(GetVehicleAcceleration(entity),GetVehicleEngineHealth(entity),GetVehicleBodyHealth(entity))
    elseif kind==3 then
        lines[#lines+1]=('Health: %s'):format(GetEntityHealth(entity))
    end
    return lines
end
local function copyEntityInfo(entity)
    local c=GetEntityCoords(entity)
    local r=GetEntityRotation(entity,2)
    lib.setClipboard(('Model Name:\\t%s\\nModel Hash:\\t%s\\n\\nHeading:\\t%.2f\\nCoords:\\t\\tvector3(%.2f, %.2f, %.2f)\\nRotation:\\tvector3(%.2f, %.2f, %.2f)'):format(entityName(entity),GetEntityModel(entity),GetEntityHeading(entity),c.x,c.y,c.z,r.x,r.y,r.z))
    notify('Full entity information copied.','success')
end
RegisterNetEvent('pm-devcoords:devadmin:copyEntity',function()
    local hit,_,entity=aimed()
    if not hit or not entity or entity==0 or not DoesEntityExist(entity) then return notify('Aim at an entity first.','error') end
    copyEntityInfo(entity)
end)
local function deleteAimed(entity)
    if entity==PlayerPedId() or (IsEntityAPed(entity) and IsPedAPlayer(entity)) then return notify('Cannot delete players.','error') end
    if NetworkGetEntityIsNetworked(entity) then
        NetworkRequestControlOfEntity(entity)
        local limit=GetGameTimer()+1000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer()<limit do Wait(0); NetworkRequestControlOfEntity(entity) end
        if not NetworkHasControlOfEntity(entity) then return notify('No network control over entity.','error') end
    end
    SetEntityAsMissionEntity(entity,true,true)
    DeleteEntity(entity)
    if DoesEntityExist(entity) then notify('Could not delete entity.','error') else notify('Entity deleted.','success') end
end
local function toggleFreeze(entity)
    if entity==PlayerPedId() or (IsEntityAPed(entity) and IsPedAPlayer(entity)) then return notify('Cannot freeze players.','error') end
    local nextState=not frozen[entity]
    if NetworkGetEntityIsNetworked(entity) then
        NetworkRequestControlOfEntity(entity)
        local limit=GetGameTimer()+1000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer()<limit do Wait(0); NetworkRequestControlOfEntity(entity) end
        if not NetworkHasControlOfEntity(entity) then return notify('No network control over entity.','error') end
    end
    FreezeEntityPosition(entity,nextState)
    frozen[entity]=nextState
    notify(nextState and 'Entity frozen.' or 'Entity unfrozen.','success')
end
local function showNearby()
    local ped=PlayerPedId()
    local origin=GetEntityCoords(ped)
    local found={}
    local function scan(first,nextFn,endFn,allowed)
        local handle,entity=first()
        if not handle or handle==-1 then return end
        local ok=true
        while ok do
            if entity and entity~=0 and DoesEntityExist(entity) and allowed(entity) then
                local coords=GetEntityCoords(entity)
                if #(coords-origin)<=maxDistance then
                    found[#found+1]={entity=entity,coords=coords}
                end
            end
            ok,entity=nextFn(handle)
        end
        endFn(handle)
    end
    if showObjects then scan(FindFirstObject,FindNextObject,EndFindObject,function() return true end) end
    if showVehicles then scan(FindFirstVehicle,FindNextVehicle,EndFindVehicle,function() return true end) end
    if showPeds then scan(FindFirstPed,FindNextPed,EndFindPed,function(entity) return entity~=ped and not IsPedAPlayer(entity) end) end
    return found
end
CreateThread(function()
    while true do
        if enabled or showObjects or showVehicles or showPeds then
            if enabled then
                local hit,pos,entity=aimed()
                label(0.35,0.015,'ENTITY VIEW | E Delete | G Freeze | H Copy coords')
                local hasEntity=hit and entity and entity~=0 and DoesEntityExist(entity)
                local color=hasEntity and {0,255,0,200} or {255,255,255,200}
                local from=GetEntityCoords(PlayerPedId())
                DrawLine(from.x,from.y,from.z,pos.x,pos.y,pos.z,color[1],color[2],color[3],color[4])
                DrawMarker(28,pos.x,pos.y,pos.z,0,0,0,0,0,0,0.12,0.12,0.12,color[1],color[2],color[3],color[4],false,true,2,false,nil,nil,false)
                if hasEntity then for i,line in ipairs(entityDetails(entity)) do label(0.35,0.035+i*0.022,line) end end
                if IsControlJustReleased(0,74) and hit then copyCoords(pos) end
                if hasEntity then
                    if IsControlJustReleased(0,47) then toggleFreeze(entity) end
                    if IsControlJustReleased(0,38) then deleteAimed(entity) end
                end
            end
            for _,item in ipairs(showNearby()) do
                local screen,x,y=World3dToScreen2d(item.coords.x,item.coords.y,item.coords.z+0.5)
                if screen then label(x,y,('Model %s | Entity %s'):format(GetEntityModel(item.entity),item.entity)) end
            end
            Wait(0)
        else Wait(250) end
    end
end)
RegisterNetEvent('pm-devcoords:devadmin:entityview',function(action)
    if action=='aim' then enabled=not enabled
    elseif action=='objects' then showObjects=not showObjects
    elseif action=='vehicles' then showVehicles=not showVehicles
    elseif action=='peds' then showPeds=not showPeds
    elseif action=='distance' then
        local input=lib.inputDialog('Entity view distance',{{type='number',label='Distance in meters',default=maxDistance,min=1,max=100,required=true}})
        if input then maxDistance=input[1] end
    end
    notify('Entity viewer settings updated.')
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then enabled=false; showObjects=false; showVehicles=false; showPeds=false end
end)
