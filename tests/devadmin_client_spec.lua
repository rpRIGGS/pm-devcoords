-- Execute the actual developer client port against FiveM/ox_lib mocks.
local events, threads, commands, contexts, clipboard = {}, {}, {}, {}, nil
exports={['qb-core']={GetCoreObject=function() return {Functions={GetVehicleProperties=function() return {model=123,plate='DEV123'} end}} end}}
lib={
  notify=function() end,
  setClipboard=function(v) clipboard=v end,
  requestModel=function() end,
  registerContext=function(v) contexts[v.id]=v end,
  showContext=function(id) assert(id:match('^pm_devcoords_')) end,
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
TriggerServerEvent=function(name,props) assert(name=='pm-devcoords:collector:toggle' or (name=='pm-devcoords:devadmin:savecar' and props.plate=='DEV123')) end
ExecuteCommand=function(cmd) commands[#commands+1]=cmd end
TriggerEvent=function(name,action)
  if name=='pm-devcoords:devadmin:entityStatus' then return action({aim=false,objects=false,vehicles=false,peds=false}) end
  if name=='pm-devcoords:devadmin:entityview' then return end
  assert(events[name], 'missing event '..name)
  events[name](action)
end
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
assert(menu and #menu.options == 4)
local categories={}
for _,v in ipairs(menu.options) do categories[v.title]=v end
for _,title in ipairs({'Coordinates','Entities','Vehicles','Utilities'}) do
  assert(categories[title], 'missing category '..title)
  categories[title].onSelect()
end
local function options(id, expected)
  local ctx=contexts[id]
  assert(ctx and ctx.menu=='pm_devcoords_devadmin', 'missing parent navigation for '..id)
  local found={}
  for _,v in ipairs(ctx.options) do found[v.title]=v end
  for _,title in ipairs(expected) do assert(found[title], 'missing '..title..' in '..id) end
  return found
end
local coords=options('pm_devcoords_coordinates',{'Coordinate collector','Copy vector2','Copy vector3','Copy vector4','Copy heading','Toggle live coordinates'})
options('pm_devcoords_entities',{'Free aim viewer (E/G/H)','Nearby objects','Nearby vehicles','Nearby peds','Viewer distance','Copy aimed entity information'})
options('pm_devcoords_vehicles',{'Toggle vehicle developer HUD','Max vehicle upgrades','Save current vehicle (/admincar)'})
local utilities=options('pm_devcoords_utilities',{'Teleport to waypoint','Set ped model'})
assert(utilities['Teleport to waypoint'].description=='Must set a waypoint on the map first')
assert(contexts.pm_devcoords_entities.options[1].icon=='power-off' and contexts.pm_devcoords_entities.options[1].iconColor=='red')
assert(contexts.pm_devcoords_vehicles.options[1].icon=='power-off' and contexts.pm_devcoords_vehicles.options[1].iconColor=='red')
assert(coords['Toggle live coordinates'].icon=='power-off' and coords['Toggle live coordinates'].iconColor=='red')
coords['Toggle live coordinates'].onSelect()
assert(contexts.pm_devcoords_coordinates.options[6].iconColor=='green')
events['pm-devcoords:devadmin:entityStateChanged']({aim=true,objects=false,vehicles=false,peds=false})
events['pm-devcoords:devadmin:open']()
contexts.pm_devcoords_devadmin.options[2].onSelect()
assert(contexts.pm_devcoords_entities.options[1].iconColor=='green')
coords['Coordinate collector'].onSelect()
assert(commands[#commands]~='devcoordscollector')
coords['Copy vector3'].onSelect()
assert(commands[#commands]=='vector3')
utilities['Set ped model'].onSelect()
assert(commands[#commands]=='setmodel mp_m_freemode_01')
print('PASS: developer client events, clipboard, vehicle upgrades/save, ox_lib menu, exclusions')
