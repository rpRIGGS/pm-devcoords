local active, groups, selectedGroup, selectedCollection = false, {}, nil, nil
local format, point, heading = 'vector4', nil, 0.0
local lastDisplay = 0
local function notify(msg, kind) lib.notify({title='PM DevCoords',description=msg,type=kind or 'inform'}) end
RegisterNetEvent('pm-devcoords:notify', notify)
RegisterNetEvent('pm-devcoords:data', function(data) groups = data or {} end)
local function aim()
    local origin, rot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(z)*math.cos(x), math.cos(z)*math.cos(x), math.sin(x))
    local dest = origin + dir * (Config.MaxDistance or 80.0)
    local ray = StartShapeTestRay(origin.x,origin.y,origin.z,dest.x,dest.y,dest.z,-1,PlayerPedId(),0)
    local _, hit, pos = GetShapeTestResult(ray)
    return hit == 1 and pos or dest, rot.z % 360.0
end
local function capture(name)
    if not active or not point then return end
    if not selectedGroup or not selectedCollection then return notify('Choose a collection with /devcoordsmenu.','error') end
    local list = groups[selectedGroup] and groups[selectedGroup][selectedCollection] or {}
    TriggerServerEvent('pm-devcoords:capture',selectedGroup,selectedCollection,{
        name=name or ('Point_%02d'):format(#list+1),format=format,
        coords={x=point.x,y=point.y,z=point.z,h=heading}
    })
end
local function menu()
    if not active then return notify('Start /devcoords first.','error') end
    local opts = {
        {title='New group / collection',onSelect=function()
            local input=lib.inputDialog('New collection',{
                {type='input',label='Group',required=true,default=selectedGroup},
                {type='input',label='Subgroup (optional, e.g. Row_01)'},
                {type='input',label='Collection (e.g. SideA)',required=true}})
            if not input then return end
            selectedGroup=input[1]
            selectedCollection=(input[2] and input[2] ~= '' and (input[2] .. '/') or '') .. input[3]
            TriggerServerEvent('pm-devcoords:create',selectedGroup,selectedCollection)
        end},
        {title='Format: '..format,onSelect=function()
            format=format=='vector4' and 'vector3' or 'vector4'
            notify('Selected '..format)
        end}
    }
    local names={}
    for g in pairs(groups) do names[#names+1]=g end
    table.sort(names)
    for _,g in ipairs(names) do
        local collections={}
        for c in pairs(groups[g]) do collections[#collections+1]=c end
        table.sort(collections)
        for _,c in ipairs(collections) do
            local group,collection=g,c
            opts[#opts+1]={title=group..' / '..collection,description=#groups[g][c]..' points',
                onSelect=function() selectedGroup,selectedCollection=group,collection notify('Selected '..collection) end}
        end
    end
    if selectedGroup and selectedCollection then
        opts[#opts+1]={title='Capture point',onSelect=function() capture() end}
        opts[#opts+1]={title='Capture named point',onSelect=function()
            local input=lib.inputDialog('Point name',{{type='input',label='Name',required=true}})
            if input then capture(input[1]) end
        end}
        opts[#opts+1]={title='Undo last point',onSelect=function()
            TriggerServerEvent('pm-devcoords:undo',selectedGroup,selectedCollection)
        end}
        opts[#opts+1]={title='Export group',onSelect=function()
            TriggerServerEvent('pm-devcoords:export',selectedGroup)
        end}
    end
    lib.registerContext({id='pm_devcoords',title='PM DevCoords',options=opts})
    lib.showContext('pm_devcoords')
end
RegisterNetEvent('pm-devcoords:toggle',function()
    active=not active
    SendNUIMessage({action=active and 'open' or 'close'})
    if not active then return end
    TriggerServerEvent('pm-devcoords:request')
    CreateThread(function()
        Wait(250)
        if active then menu() end
    end)
    CreateThread(function()
        while active do
            point,heading=aim()
            local ped=GetEntityCoords(PlayerPedId())
            local color=Config.LineColor
            DrawLine(ped.x,ped.y,ped.z+0.2,point.x,point.y,point.z,color.r,color.g,color.b,color.a)
            if Config.DrawMarker then
                local c,s=Config.MarkerColor,Config.MarkerScale
                DrawMarker(28,point.x,point.y,point.z+0.05,0,0,0,0,0,0,s,s,s,c.r,c.g,c.b,c.a,false,false,2,false,nil,nil,false)
            end
            if GetGameTimer() - lastDisplay >= 120 then
                lastDisplay = GetGameTimer()
                SendNUIMessage({action='update',
                vec3=('vector3(%.3f, %.3f, %.3f)'):format(point.x,point.y,point.z),
                vec4=('vector4(%.3f, %.3f, %.3f, %.2f)'):format(point.x,point.y,point.z,heading),
                context=(selectedGroup or 'No group')..' / '..(selectedCollection or 'No collection')})
            end
            Wait(0)
        end
    end)
end)
RegisterCommand('devcoordsmenu',menu,false)
RegisterCommand('devcoords_capture',function() capture() end,false)
RegisterCommand('devcoords_undo',function()
    if active and selectedGroup and selectedCollection then
        TriggerServerEvent('pm-devcoords:undo',selectedGroup,selectedCollection)
    end
end,false)
RegisterKeyMapping('devcoords_capture','PM DevCoords capture point','keyboard','J')
RegisterKeyMapping('devcoords_undo','PM DevCoords undo point','keyboard','K')
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then active=false SendNUIMessage({action='close'}) end
end)
