-- Execute actual client/main.lua with mocked FiveM and ox_lib interfaces.
local events, commands, threads, serverEvents, messages, contexts = {}, {}, {}, {}, {}, {}
local now, hit = 1000, 1
local selectedMenu, lastNotify
local function v(x,y,z)
  return setmetatable({x=x,y=y,z=z}, {__add=function(a,b) return v(a.x+b.x,a.y+b.y,a.z+b.z) end,
    __mul=function(a,b) if type(a)=='number' then return v(a*b.x,a*b.y,a*b.z) end return v(a.x*b,a.y*b,a.z*b) end})
end
vector3=v
Config={MaxDistance=80,LineColor={r=1,g=2,b=3,a=4},MarkerColor={r=1,g=2,b=3,a=4},MarkerScale=.18,DrawMarker=true}
lib={
  notify=function(data) lastNotify=data end,
  registerContext=function(data) contexts[data.id]=data end,
  showContext=function(id) selectedMenu=id end,
  inputDialog=function() return nil end
}
RegisterNetEvent=function(n,fn) events[n]=fn end
RegisterCommand=function(n,fn) commands[n]=fn end
RegisterKeyMapping=function() end
AddEventHandler=function(n,fn) events[n]=fn end
TriggerServerEvent=function(n,...) serverEvents[#serverEvents+1]={name=n,args={...}} end
SendNUIMessage=function(data) messages[#messages+1]=data end
CreateThread=function(fn) threads[#threads+1]=fn end
GetGameplayCamCoord=function() return v(0,0,5) end
GetGameplayCamRot=function() return {x=0,z=90} end
PlayerPedId=function() return 1 end
GetEntityCoords=function() return v(0,0,0) end
StartExpensiveSynchronousShapeTestLosProbe=function() return 7 end
GetShapeTestResult=function() return 2,hit,v(10,20,30) end
GetGameTimer=function() return now end
DrawLine=function() end
DrawMarker=function() end
Wait=function() error('TEST_YIELD') end
GetCurrentResourceName=function() return 'pm-devcoords' end
dofile('pm-devcoords/client/main.lua')
assert(commands.devcoordsmenu and commands.devcoords_capture and commands.devcoords_undo)
commands.devcoords_capture()
assert(#serverEvents==0)
events['pm-devcoords:toggle']()
assert(messages[#messages].action=='open')
assert(serverEvents[#serverEvents].name=='pm-devcoords:request')
events['pm-devcoords:data']({Test={Row={}}})
assert(selectedMenu=='pm_devcoords')
local select
for _,item in ipairs(contexts.pm_devcoords.options) do
  if item.title=='Test / Row' then select=item.onSelect end
end
assert(select)
select()
assert(lastNotify.description=='Selected Row')
local ok,err=pcall(threads[#threads])
assert(not ok and tostring(err):find('TEST_YIELD'))
assert(messages[#messages].action=='update')
assert(messages[#messages].vector3=='vector3(10.000, 20.000, 30.000)')
assert(messages[#messages].vector4=='vector4(10.000, 20.000, 30.000, 270.00)')
commands.devcoords_capture()
assert(serverEvents[#serverEvents].name=='pm-devcoords:capture')
assert(serverEvents[#serverEvents].args[3].format=='vector4')
assert(serverEvents[#serverEvents].args[3].name==nil)
commands.devcoords_undo()
assert(serverEvents[#serverEvents].name=='pm-devcoords:undo')
events['pm-devcoords:toggle']()
assert(messages[#messages].action=='close')
commands.devcoords_capture()
assert(serverEvents[#serverEvents].name=='pm-devcoords:undo')
events['pm-devcoords:toggle']()
hit=0
now=1100
ok,err=pcall(threads[#threads])
assert(not ok and tostring(err):find('TEST_YIELD'))
commands.devcoords_capture()
assert(lastNotify.description=='Aim at a surface before capturing.')
events['pm-devcoords:toggle']()
print('PASS: toggle, menu, NUI contract, camera heading, capture, undo, no-hit protection, close')
