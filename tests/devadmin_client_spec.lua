-- Execute the actual developer client port against FiveM/ox_lib mocks.
local events, threads, commands, contexts, clipboard = {}, {}, {}, {}, nil
exports={['qb-core']={GetCoreObject=function() return {Functions={GetVehicleProperties=function() return {model=123,plate='DEV123'} end}} end}}
lib={
  notify=function() end,
  setClipboard=function(v) clipboard=v end,
  requestModel=function() end,
  registerContext=function(v) contexts[v.id]=v end,
  showContext=function(id) assert(id=='pm_devcoords_devadmin') end,
  inputDialog=function() return {'mp_m_freemode_01'} end
}
RegisterNetEvent=function(name,fn) events[name]=fn end
CreateThread=function(fn) threads[#threads+1]=fn end
PlayerPedId=function() return 10 end
PlayerId=function() return 1 end
GetEntityCoords=function() return {x=1.25,y=2.5,z=3.75} end
GetEntityHeading=function() return 90 end
GetVehiclePedIsIn=function() return 20 end
GetPedInVehicleSeat=function() return 10 end
SetVehicleModKit=function() end
GetNumVehicleMods=function() return 3 end
SetVehicleMod=function() end
ToggleVehicleMod=function() end
SetVehicleFixed=function() end
TriggerServerEvent=function(name,props) assert(name=='pm-devcoords:devadmin:savecar' and props.plate=='DEV123') end
ExecuteCommand=function(cmd) commands[#commands+1]=cmd end
TriggerEvent=function(name,action) events[name](action) end
dofile('pm-devcoords/client/devadmin.lua')
for _,name in ipairs({'copy','coords','admincar','maxmods','setmodel','open'}) do
  assert(events['pm-devcoords:devadmin:'..name], 'missing client event '..name)
end
events['pm-devcoords:devadmin:copy']('vector4')
assert(clipboard=='vector4(1.25, 2.50, 3.75, 90.00)')
events['pm-devcoords:devadmin:admincar']()
events['pm-devcoords:devadmin:maxmods']()
events['pm-devcoords:devadmin:open']()
local menu=contexts.pm_devcoords_devadmin
assert(menu and #menu.options >= 15)
local titles={}
for _,v in ipairs(menu.options) do titles[v.title]=v end
for _,title in ipairs({'Coordinate collector','Copy vector2','Copy vector3','Copy vector4','Copy heading','Toggle live coordinates','Toggle vehicle developer HUD','Entity viewer: free aim (E/G/H)','Entity viewer: nearby objects','Entity viewer: nearby vehicles','Entity viewer: nearby peds','Entity viewer: distance','Copy full aimed entity information','Max vehicle upgrades','Save vehicle (/admincar)','Teleport to waypoint','Set ped model'}) do
  assert(titles[title], 'missing developer menu option '..title)
end
for _,title in ipairs({'God mode','High jump','Movement speed','NoClip','Spawn vehicle'}) do
  assert(not titles[title], 'duplicate admin menu option '..title)
end
titles['Copy vector3'].onSelect()
assert(commands[#commands]=='vector3')
titles['Set ped model'].onSelect()
assert(commands[#commands]=='setmodel mp_m_freemode_01')
print('PASS: developer client events, clipboard, vehicle upgrades/save, ox_lib menu, exclusions')
