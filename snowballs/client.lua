local isPicking = false

local function isInInterior()
    local interior = GetInteriorFromEntity(cache.ped)
    return interior and interior ~= 0
end

CreateThread(function()
    SetWeaponDamageModifier(joaat("WEAPON_SNOWBALL"), 0.0)
end)

exports.ox_target:addGlobalPlayer({
    me = true,
    name = 'player:pick:snowball',
    icon = 'fa-solid fa-snowball',
    label = "Récupérer une boule de neige",
    distance = 2.0,
    onSelect = function(data)
        isPicking = true
        lib.playAnim(cache.ped, 'anim@mp_snowball', 'pickup_snowball')
        Wait(1950)
        lib.callback.await('snowballs:server:get', 2000)
        isPicking = false
    end,
    canInteract = function(entity, distance, data)
        if cache.vehicle then return false end
        if not IsPedOnFoot(cache.ped) then return false end
        if QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand then return false end
        if LocalPlayer.state.dead then return false end
        if isInInterior() then return false end
        if isPicking then return false end
        return true
    end
})