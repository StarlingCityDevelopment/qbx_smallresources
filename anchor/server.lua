lib.callback.register('anchor:toggle', function(src, netId)
    if not src or not netId then return false end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    if GetVehicleType(vehicle) ~= 'boat' then return false end

    local isAnchored = Entity(vehicle).state.isAnchored or false
    local shouldAnchor = not isAnchored
    Entity(vehicle).state.isAnchored = shouldAnchor

    lib.notify(src, {
        title = 'Ancre',
        description = shouldAnchor and 'Le bateau a été ancré.' or 'Le bateau a été désancré.',
        type = 'success'
    })

    return shouldAnchor
end)