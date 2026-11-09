-- Exercise the imported qb-adminmenu entity viewer with native mocks.
local events, tasks, pressed, notifications, clipboard, frozen, deleted = {}, {}, {}, {}, nil, nil, false
local function v(x,y,z)
 return setmetatable({x=x,y=y,z=z},{__sub=function(a,b) return v(a.x-b.x,a.y-b.y,a.z-b.z) end,__len=function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end})
end
vector3=v
lib={notify=function(t) notifications[#notifications+1]=t end,setClipboard=function(t) clipboard=t end,inputDialog=function() return {25} end}
RegisterNetEvent=function(name,fn) events[name]=fn end
Citizen={CreateThread=function(fn) tasks[#tasks+1]=fn end,Wait=function() error('TEST_YIELD') end}
PlayerPedId=function() return 1 end
IsGameplayCamRendering=function() return true end
GetGameplayCamRot=function() return {x=0,y=0,z=0} end
GetGameplayCamCoord=function() return v(0,0,5) end
StartExpensiveSynchronousShapeTestLosProbe=function() return 9 end
local hit, entity = true, 2
GetShapeTestResult=function() return 2,hit,v(1,2,3),v(0,0,1),entity end
DoesEntityExist=function(id) return id==2 and not deleted end
IsEntityAVehicle=function(id) return id==2 end
IsEntityAPed=function() return false end
IsEntityAnObject=function() return false end
GetEntityType=function() return 2 end
GetEntityModel=function() return 123 end
GetDisplayNameFromVehicleModel=function() return 'TESTCAR' end
local networked, control, requests = false, true, 0
NetworkGetEntityIsNetworked=function() return networked end
NetworkHasControlOfEntity=function() return control end
NetworkRequestControlOfEntity=function() requests=requests+1 end
GetEntityCoords=function(id) return id==1 and v(0,0,0) or v(1,2,3) end
GetEntityHeading=function() return 90 end
GetEntityRotation=function() return v(0,0,0) end
GetEntityVelocity=function() return v(0,0,0) end
GetEntitySpeed=function() return 0 end
GetVehicleCurrentRpm=function() return 0 end
GetVehicleCurrentGear=function() return 1 end
GetVehicleAcceleration=function() return 0 end
GetVehicleBodyHealth=function() return 1000 end
GetVehicleEngineHealth=function() return 1000 end
GetModelDimensions=function() return v(-1,-1,-1),v(1,1,1) end
GetEntityMatrix=function() return v(0,1,0),v(1,0,0),v(0,0,1),v(1,2,3) end
local lines=0
DrawLine=function() lines=lines+1 end
DrawMarker=function() end
DrawRect=function() end
SetTextScale=function() end
SetTextFont=function() end
SetTextDropshadow=function() end
SetTextColour=function() end
SetTextJustification=function() end
BeginTextCommandDisplayText=function() end
AddTextComponentSubstringPlayerName=function() end
EndTextCommandDisplayText=function() end
SetTextEdge=function() end
IsControlJustReleased=function(_,key) return pressed[key] or false end
FreezeEntityPosition=function(_,flag) frozen=flag end
SetEntityAsMissionEntity=function() end
DeleteEntity=function() deleted=true end
dofile('pm-devcoords/client/entity_view.lua')
assert(events['pm-devcoords:devadmin:entityview'] and events['pm-devcoords:devadmin:copyEntity'])
events['pm-devcoords:devadmin:copyEntity']()
assert(clipboard:find('Model Name: TESTCAR',1,true) and clipboard:find('Coords: vector3(1.00, 2.00, 3.00)',1,true))
events['pm-devcoords:devadmin:entityview']('aim')
assert(#tasks==1)
local function frame()
 local ok,err=pcall(tasks[#tasks])
 assert(not ok and tostring(err):find('TEST_YIELD'))
end
-- Wait happens before drawing; make it yield once then return for deterministic one-frame checks.
Citizen.Wait=function() end
local calls=0
Citizen.Wait=function() calls=calls+1;if calls>1 then error('TEST_YIELD') end end
local function runframe()
 calls=0
 local ok,err=pcall(tasks[#tasks])
 assert(not ok and tostring(err):find('TEST_YIELD'),tostring(err))
end
pressed[74]=true
runframe()
assert(clipboard=='vector3(1.0, 2.0, 3.0)')
assert(lines>=12,'3D bounding box not drawn')
pressed[74]=nil
pressed[47]=true
networked=true
control=false
runframe()
assert(requests==1 and frozen==nil, 'networked entity frozen without control')
control=true
runframe()
assert(frozen==true)
runframe()
assert(frozen==false)
pressed[47]=nil
pressed[38]=true
control=false
runframe()
assert(requests==2 and deleted==false, 'networked entity deleted without control')
control=true
runframe()
assert(deleted==true)
pressed[38]=nil
hit=false
events['pm-devcoords:devadmin:copyEntity']()
assert(notifications[#notifications].type=='error')
print('PASS: entity viewer original E/G/H, bounding-box lines, full entity copy, missing-target guard')
