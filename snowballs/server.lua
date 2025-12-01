local cooldowns = {}

lib.callback.register('snowballs:server:get', function (src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return
    end
    if cooldowns[src] and os.time() < cooldowns[src] then
        return
    end
    exports.ox_inventory:AddItem(src, 'WEAPON_SNOWBALL', 1)
    cooldowns[src] = os.time() + 1.95
end)