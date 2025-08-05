RegisterNetEvent('cdx:fastactions:server:TacklePlayer', function(target)
    local src = source

    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local targetCoords = GetEntityCoords(GetPlayerPed(target))

    if #(srcCoords - targetCoords) > 2.0 then
        -- Ban player
        return
    end

    TriggerClientEvent('cdx:fastactions:client:GetTackled', target)
end)
