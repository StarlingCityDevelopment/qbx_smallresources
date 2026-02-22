lib.callback.register('cdx_hideintrunk:server:tryOccupyTrunk', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return false end

    local state = Entity(vehicle).state
    if state.trunkOccupied then
        return false
    end

    state:set('trunkOccupied', true, true)
    return true
end)

RegisterNetEvent('cdx_hideintrunk:server:setTrunkOccupied', function(netId, state)
    local src = source

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    Entity(vehicle).state:set('trunkOccupied', state, true)
end)