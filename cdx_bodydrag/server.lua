local function distanceCheck(src, target)
    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)

    if srcPed and targetPed then
        local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
        if dist > 3.0 then
            return false
        end
    end

    return true
end

lib.callback.register('cdx:bodydrag:server:isPlayerDead', function(_, playerId)
    if not playerId then return false end
    if not distanceCheck(source, playerId) then return false end
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return false end
    return player.PlayerData.metadata.isdead
end)

RegisterServerEvent('cdx:bodydrag:server:setDragEscort', function(target, state)
    local src = source

    if not distanceCheck(src, target) then return end

    local srcPlayer = exports.qbx_core:GetPlayer(src)
    if not srcPlayer then return end

    local targetPlayer = exports.qbx_core:GetPlayer(target)
    if not targetPlayer then return end

    local srcState = Player(src)?.state
    local targetState = Player(target)?.state

    if targetState then
        targetState:set('isDragged', state and src or nil, true)
    end

    if srcState then
        srcState:set('isDragging', state and target or nil, true)
    end
end)