local function PMRound(n, d) local p=10^(d or 0); return math.floor(n*p+0.5)/p end
local function PMNotify(msg, kind) lib.notify({title='PM DevCoords',description=tostring(msg),type=kind or 'inform'}) end
local FrozenEntities     = {}
local EntityViewDistance = 10
local EntityViewEnabled  = false
local EntityFreeAim      = false
local EntityPedView      = false
local EntityObjectView   = false
local EntityVehicleView  = false
local FreeAimEntity      = nil

-- Configurable values
local FreeAimInfoBoxX    = 0.60 -- X-axis (0.0 being left, 1.0 being right position of the screen)
local FreeAimInfoBoxY    = 0.02 -- Y-axis (0.0 being up, 1.0 being down position of the screen)
local useKph             = true -- True to display KPH or false to display MPH

local CanEntityBeUsed    = function(ped)
    if ped == PlayerPedId() then
        return false
    end
    return true
end

local RoundFloat         = function(number, num)
    return math.floor(number * math.pow(10, num) + 0.5) / math.pow(10, num)
end

local RoundVector3       = function(vector, num)
    return 'vector3(' .. RoundFloat(vector.x, num) .. ', ' .. RoundFloat(vector.y, num) .. ', ' .. RoundFloat(vector.z, num) .. ')'
end


local RelationshipTypes = { ['0'] = 'Companion', ['1'] = 'Respect', ['2'] = 'Like', ['3'] = 'Neutral', ['4'] = 'Dislike', ['5'] = 'Hate', ['255'] = 'Pedestrians' }
local GetPedRelationshipType = function(value)
    value = tostring(value)
    return RelationshipTypes[value] or 'Unknown'
end

local DrawTitle = function(text)
    SetTextScale(0.50, 0.50)
    SetTextFont(4)
    SetTextDropshadow(1.0, 0, 0, 0, 255)
    SetTextColour(255, 255, 255, 215)
    SetTextJustification(0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.02)
end

local RotationToDirection = function(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local RayCastGamePlayCamera = function(distance)
    -- Checks to see if the Gameplay Cam is Rendering or another is rendering (no clip functionality)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        local cam = GetRenderingCam()
        if cam and cam ~= 0 and DoesCamExist(cam) then currentRenderingCam = cam end
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local handle = StartExpensiveSynchronousShapeTestLosProbe(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 7)
    local _, hit, coords, _, entity = GetShapeTestResult(handle)
    return hit == true or hit == 1, coords or vector3(destination.x,destination.y,destination.z), entity or 0
end

local DrawEntityBoundingBox = function(entity, color)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    local minimum, maximum = GetModelDimensions(GetEntityModel(entity))
    local forward, right, up, position = GetEntityMatrix(entity)
    if not minimum or not maximum then return end
    color = color or {r=255,g=255,b=255,a=255}
    local corners = {}
    for _, x in ipairs({minimum.x, maximum.x}) do
        for _, y in ipairs({minimum.y, maximum.y}) do
            for _, z in ipairs({minimum.z, maximum.z}) do
                corners[#corners+1] = vector3(
                    position.x + right.x*x + forward.x*y + up.x*z,
                    position.y + right.y*x + forward.y*y + up.y*z,
                    position.z + right.z*x + forward.z*y + up.z*z
                )
            end
        end
    end
    for i=1,8 do
        for _, bit in ipairs({1,2,4}) do
            local j = ((i-1) ~ bit) + 1
            if j > i then
                local a,b = corners[i],corners[j]
                DrawLine(a.x,a.y,a.z,b.x,b.y,b.z,color.r,color.g,color.b,color.a)
            end
        end
    end
end

local GetEntityInfo = function(entity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityType   = GetEntityType(entity)
    local entityHash   = GetEntityModel(entity)
    local entityName   = (IsEntityAVehicle(entity) and GetDisplayNameFromVehicleModel(entityHash) or tostring(entityHash))
    local entityData   = { '~y~' .. "Entity Information", '', "Model hash:" .. ' ~y~' .. entityHash, ' ', "Entity ID:" .. ' ~y~' .. entity, "Model name:" .. ' ~y~' .. entityName, "Network ID:" .. ' ~y~' .. (NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 'Not networked'), "Owner:" .. ' ~y~' .. (NetworkGetEntityIsNetworked(entity) and tostring(GetPlayerServerId(NetworkGetEntityOwner(entity))) or 'Not networked'), ' ' }

    if entityType == 1 then
        local pedRelationshipGroup = GetPedRelationshipGroupHash(entity)
        entityData[#entityData + 1] = "Health:" .. ' ~y~' .. GetEntityHealth(entity)
        entityData[#entityData + 1] = "Max health:" .. ' ~y~' .. GetPedMaxHealth(entity)
        entityData[#entityData + 1] = "Armour:" .. ' ~y~' .. GetPedArmour(entity)
        entityData[#entityData + 1] = "Relationship group:" .. ' ~y~' .. (tostring(pedRelationshipGroup))
        entityData[#entityData + 1] = "Relationship to player:" .. ' ~y~' .. GetPedRelationshipType(GetRelationshipBetweenPeds(entity, PlayerPedId()))
    elseif entityType == 2 then
        entityData[#entityData + 1] = "RPM:" .. ' ~y~' .. RoundFloat(GetVehicleCurrentRpm(entity), 2)
        entityData[#entityData + 1] = (useKph and "Speed KPH:" or "Speed MPH:") .. ' ~y~' .. RoundFloat((GetEntitySpeed(entity) * (useKph and 3.6 or 2.23694)), 0)
        entityData[#entityData + 1] = "Gear:" .. ' ~y~' .. GetVehicleCurrentGear(entity)
        entityData[#entityData + 1] = "Acceleration:" .. ' ~y~' .. RoundFloat(GetVehicleAcceleration(entity), 2)
        entityData[#entityData + 1] = "Body health:" .. ' ~y~' .. GetVehicleBodyHealth(entity)
        entityData[#entityData + 1] = "Engine health:" .. ' ~y~' .. GetVehicleEngineHealth(entity)
    elseif entityType == 3 then
        entityData[#entityData + 1] = "Health:" .. ' ~y~' .. GetEntityHealth(entity)
    end
    local entityCoords = GetEntityCoords(entity)

    entityData[#entityData + 1] = ' '
    entityData[#entityData + 1] = "Distance:" .. ' ~y~' .. RoundFloat(#(playerCoords - entityCoords), 2)
    entityData[#entityData + 1] = "Heading:" .. ' ~y~' .. RoundFloat(GetEntityHeading(entity), 2)
    entityData[#entityData + 1] = "Coords:" .. ' ~y~' .. RoundVector3(entityCoords, 2)
    entityData[#entityData + 1] = "Rotation:" .. ' ~y~' .. RoundVector3(GetEntityRotation(entity), 2)
    entityData[#entityData + 1] = "Velocity:" .. ' ~y~' .. RoundVector3(GetEntityVelocity(entity), 2)

    return entityData
end

local DrawEntityViewText = function(entity)
    local data            = GetEntityInfo(entity)
    local count           = #data

    local posX            = FreeAimInfoBoxX
    local posY            = FreeAimInfoBoxY
    local titleSpacing    = 0.03
    local textSpacing     = 0.022
    local titeLeftMargin  = 0.05
    local paddingTop      = 0.02
    local paddingLeft     = 0.005
    local rectWidth       = 0.18
    local heightOfContent = (((count) * textSpacing) + titleSpacing) / count
    local rectHeight      = ((count - 1) * heightOfContent) + paddingTop

    DrawRect(posX + (rectWidth / 2), posY + ((rectHeight / 2) - posY / 2), rectWidth, rectHeight, 11, 11, 11, 200)

    for k, v in ipairs(data) do
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextDropshadow(1.0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextColour(255, 255, 255, 215)
        SetTextJustification(1)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(v)
        if k == 1 then
            SetTextScale(0.50, 0.50)
            EndTextCommandDisplayText(posX + titeLeftMargin, posY)
            posY = posY + titleSpacing
        else
            SetTextScale(0.35, 0.35)
            EndTextCommandDisplayText(posX + paddingLeft, posY)
            posY = posY + textSpacing
        end
    end
end

local DrawEntityViewTextInWorld = function(entity, coords)
    local onScreen, posX, posY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        local data        = GetEntityInfo(entity)
        local count       = #data
        local textOffsetY = 0.015
        local leftPadding = 0.005
        local topPadding  = 0.01
        local botPadding  = 0.02
        local offSetCount = (((count - 2) * textOffsetY)) / count
        local rectWidth   = 0.12
        local rectHeight  = ((count) * offSetCount) + botPadding

        DrawRect(posX, posY, rectWidth, rectHeight, 11, 11, 11, 200)

        for k, v in ipairs(data) do
            if k ~= 1 and k ~= 2 then
                SetTextScale(0.25, 0.25)
                SetTextFont(4)
                SetTextDropshadow(1.0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextColour(255, 255, 255, 215)
                SetTextJustification(1)
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(v)
                EndTextCommandDisplayText(posX - rectWidth / 2 + leftPadding, posY - rectHeight / 2 + topPadding)
                posY = posY + textOffsetY
            end
        end
    end
end

local GetVehicle = function(playerCoords)
    local handle, vehicle = FindFirstVehicle()
    if not handle or handle == -1 then return nil end
    local success
    local rveh = nil
    repeat
        if vehicle ~= FreeAimEntity then
            local pos = GetEntityCoords(vehicle)
            local distance = #(playerCoords - pos)
            if distance < EntityViewDistance and distance > 5.0 then
                DrawEntityBoundingBox(vehicle)
            elseif distance < 5.0 then
                rveh = vehicle
                DrawEntityViewTextInWorld(vehicle, pos)
            end
        end
        success, vehicle = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return rveh
end

local GetObject = function(playerCoords)
    local handle, object = FindFirstObject()
    if not handle or handle == -1 then return nil end
    local success
    local robject = nil
    repeat
        if object ~= FreeAimEntity then
            local pos = GetEntityCoords(object)
            local distance = #(playerCoords - pos)
            if distance < EntityViewDistance and distance > 5.0 then
                DrawEntityBoundingBox(object)
            elseif distance < 5.0 then
                robject = object
                DrawEntityViewTextInWorld(object, pos)
            end
        end
        success, object = FindNextObject(handle)
    until not success
    EndFindObject(handle)
    return robject
end

local GetNPC = function(playerCoords)
    local handle, ped = FindFirstPed()
    if not handle or handle == -1 then return nil end
    local success
    local rped = nil
    repeat
        if ped ~= FreeAimEntity then
            local pos = GetEntityCoords(ped)
            local distance = #(playerCoords - pos)
            if CanEntityBeUsed(ped) then
                if distance < EntityViewDistance and distance > 5.0 then
                    DrawEntityBoundingBox(ped)
                elseif distance < 5.0 then
                    rped = ped
                    DrawEntityViewTextInWorld(ped, pos)
                end
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return rped
end

ToggleEntityFreeView = function()
    EntityFreeAim = not EntityFreeAim
    if EntityFreeAim and not EntityViewEnabled then
        RunEntityViewThread()
    end
end

ToggleEntityObjectView = function()
    EntityObjectView = not EntityObjectView
    if EntityObjectView and not EntityViewEnabled then
        RunEntityViewThread()
    end
end

ToggleEntityVehicleView = function()
    EntityVehicleView = not EntityVehicleView
    if EntityVehicleView and not EntityViewEnabled then
        RunEntityViewThread()
    end
end

ToggleEntityPedView = function()
    EntityPedView = not EntityPedView
    if EntityPedView and not EntityViewEnabled then
        RunEntityViewThread()
    end
end

GetCurrentEntityViewDistance = function()
    return EntityViewDistance / 5
end

SetEntityViewDistance = function(data)
    EntityViewDistance = tonumber(data)
end

GetFreeAimEntity = function()
    return FreeAimEntity
end

RunEntityViewThread = function()
    EntityViewEnabled = true
    Citizen.CreateThread(function()
        while EntityViewEnabled do
            Citizen.Wait(0)
            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if EntityPedView then
                GetNPC(playerCoords)
            end

            if EntityObjectView then
                GetObject(playerCoords)
            end

            if EntityVehicleView then
                GetVehicle(playerCoords)
            end

            if EntityFreeAim then
                DrawTitle('~y~' .. "Entity Viewer" .. '~w~\n[~y~E~w~] - ' .. "Delete" .. ' ~w~[~y~G~w~] - ' .. "Freeze" .. ' ~w~[~y~H~w~] - ' .. "Copy coordinates")
                local color = { r = 255, g = 255, b = 255, a = 200 }
                local position = GetEntityCoords(playerPed)
                local hit, coords, entity = RayCastGamePlayCamera(1000.0)
                -- If entity is found then verify entity
                if hit and IsControlJustReleased(0, 74) then -- Copy Coords
                    local x = PMRound(coords.x, 2)
                    local y = PMRound(coords.y, 2)
                    local z = PMRound(coords.z, 2)
                    lib.setClipboard(string.format('vector3(%s, %s, %s)', x, y, z))
                    PMNotify("Coordinates copied", 'success')
                end
                if hit and entity ~= 0 and DoesEntityExist(entity) and (IsEntityAVehicle(entity) or IsEntityAPed(entity) or IsEntityAnObject(entity)) then
                    color = { r = 0, g = 255, b = 0, a = 200 }
                    FreeAimEntity = entity
                    DrawEntityBoundingBox(entity, color)
                    DrawEntityViewText(entity)

                    if IsControlJustReleased(0, 47) then -- Freeze entities
                        if NetworkGetEntityIsNetworked(entity) and not NetworkHasControlOfEntity(entity) then
                            NetworkRequestControlOfEntity(entity)
                            PMNotify('Entity control requested; try again.', 'error')
                        else
                            local nextFrozen = not FrozenEntities[entity]
                            FreezeEntityPosition(entity, nextFrozen)
                            FrozenEntities[entity] = nextFrozen
                            PMNotify(nextFrozen and 'Entity frozen' or 'Entity unfrozen', 'success')
                        end
                    end

                    if IsControlJustReleased(0, 38) then -- Delete entity
                        if NetworkGetEntityIsNetworked(entity) and not NetworkHasControlOfEntity(entity) then
                            NetworkRequestControlOfEntity(entity)
                            PMNotify('Entity control requested; try again.', 'error')
                        else
                            SetEntityAsMissionEntity(entity, true, true)
                            DeleteEntity(entity)
                            if not DoesEntityExist(entity) then
                                FrozenEntities[entity] = nil
                                FreeAimEntity = nil
                                PMNotify('Entity deleted', 'success')
                            else
                                PMNotify('Could not delete entity', 'error')
                            end
                        end
                    end
                else
                    FreeAimEntity = nil
                end

                DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
            end

            if EntityPedView == false and EntityObjectView == false and EntityVehicleView == false and EntityFreeAim == false then
                EntityViewEnabled = false
            end
        end
    end)
end

-- PM DevCoords ox_lib integration; the rendering and original E/G/H behavior above
-- are retained from qb-adminmenu's entity_view.lua.
local function CopyFullEntity()
    -- Use a fresh raycast; never copy an entity that was aimed at earlier.
    local hit,_,entity=RayCastGamePlayCamera(1000.0)
    if not hit or not entity or entity==0 or not DoesEntityExist(entity) then
        PMNotify('Aim at an entity first','error')
        return
    end
    local hash=GetEntityModel(entity)
    local name=IsEntityAVehicle(entity) and GetDisplayNameFromVehicleModel(hash) or tostring(hash)
    local c=GetEntityCoords(entity)
    local r=GetEntityRotation(entity)
    lib.setClipboard(table.concat({
        ('Model Name: %s'):format(name),
        ('Model Hash: %s'):format(hash),
        '',
        ('Heading: %.2f'):format(GetEntityHeading(entity)),
        ('Coords: vector3(%.2f, %.2f, %.2f)'):format(c.x,c.y,c.z),
        ('Rotation: vector3(%.2f, %.2f, %.2f)'):format(r.x,r.y,r.z)
    }, string.char(10)))
    PMNotify('Full entity information copied','success')
end
RegisterNetEvent('pm-devcoords:devadmin:copyEntity',CopyFullEntity)
RegisterNetEvent('pm-devcoords:devadmin:entityview',function(action)
    if action=='aim' then ToggleEntityFreeView()
    elseif action=='objects' then ToggleEntityObjectView()
    elseif action=='vehicles' then ToggleEntityVehicleView()
    elseif action=='peds' then ToggleEntityPedView()
    elseif action=='distance' then
        local response=lib.inputDialog('Entity viewer distance',{{type='slider',label='Distance (meters)',min=5,max=50,step=5,default=EntityViewDistance}})
        if response and response[1] then SetEntityViewDistance(response[1]) end
    end
end)
