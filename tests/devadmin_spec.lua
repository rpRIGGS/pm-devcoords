-- Regression coverage for the qb-adminmenu developer-command port.
local commands, events, sent, inserts = {}, {}, {}, {}
source = 1
exports = {['qb-core'] = {GetCoreObject = function()
    return {Functions = {
        HasPermission = function(src) return src == 1 end,
        GetPlayer = function(src) if src == 1 then return {PlayerData={license='license:test',citizenid='CID1'}} end end
    },Shared={Vehicles={adder={model='adder',hash=1234}}}}
end}}
IsPlayerAceAllowed = function(src, ace)
    assert(ace == 'command.devcoords')
    return src == 1
end
RegisterCommand = function(name, callback) commands[name]=callback end
RegisterNetEvent = function(name, callback) events[name]=callback end
TriggerClientEvent = function(name, target, ...)
    sent[#sent+1]={name=name,target=target,args={...}}
end
GetPlayerPed = function() return 11 end
GetVehiclePedIsIn = function() return 22 end
GetPedInVehicleSeat = function() return 11 end
GetVehicleNumberPlateText = function() return 'TEST123 ' end
GetEntityModel = function() return 1234 end
GetHashKey = function(model) assert(model=='adder'); return 1234 end
json = {encode=function() return '{}' end}
MySQL = {
    query={await=function() return {} end},
    insert={await=function(_,values) inserts[#inserts+1]=values;return 5 end}
}
dofile('pm-devcoords/server/devadmin.lua')
for _,name in ipairs({'devadmin','vector2','vector3','vector4','heading','coords','maxmods','admincar','setmodel'}) do
    assert(type(commands[name])=='function','missing developer command '..name)
end
for _,name in ipairs({'setspeed','noclip','repair','dv'}) do
    assert(commands[name]==nil,'duplicate admin command '..name)
end
commands.devadmin(2,{})
assert(sent[#sent].name=='pm-devcoords:notify')
commands.devadmin(1,{})
assert(sent[#sent].name=='pm-devcoords:devadmin:open')
commands.vector4(1,{})
assert(sent[#sent].name=='pm-devcoords:devadmin:copy')
assert(sent[#sent].args[1]=='vector4')
commands.maxmods(1,{})
assert(sent[#sent].name=='pm-devcoords:devadmin:maxmods')
events['pm-devcoords:devadmin:savecar']({model=1234,plate='TEST123'})
assert(#inserts==1 and inserts[1][3]=='adder' and inserts[1][6]=='TEST123')
source=2
events['pm-devcoords:devadmin:savecar']({model=1234,plate='TEST123'})
assert(#inserts==1,'unauthorized save succeeded')
source=1
events['pm-devcoords:devadmin:savecar']({model=1234,plate='WRONG'})
assert(#inserts==1,'plate spoof succeeded')
commands.setmodel(1,{'mp_m_freemode_01'})
assert(sent[#sent].name=='pm-devcoords:devadmin:setmodel')
print('PASS: developer commands, scope exclusions, permission gates, admincar DB insert and spoof rejection')
