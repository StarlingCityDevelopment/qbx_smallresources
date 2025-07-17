lib.callback.register('cdx:bodydrag:server:isPlayerDead', function(_, playerId)
    if not playerId then return false end
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return false end
    return player.PlayerData.metadata.isdead
end)

RegisterServerEvent('cdx:bodydrag:server:setDragEscort', function(target, state)
    local src = source

    target = Player(target)?.state
    local player = Player(src)?.state
    if not target or not player then return end

    target:set('isDragged', state and src, true)
    player:set('isDragging', state and src, true)
end)