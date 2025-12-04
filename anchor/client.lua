local textUI = false

local function reset()
    if not textUI then return end
    textUI = false
    lib.hideTextUI()
end

local function show(vehicle)
    reset()
    textUI = true
    local anchored = IsBoatAnchoredAndFrozen(vehicle)
    lib.showTextUI(('[E] - %s'):format(anchored and 'Désancrer' or 'Ancrer'))
end

local keybind = lib.addKeybind({
    name = 'anchor',
    description = 'press E pour ancrer/désancrer le bateau',
    defaultKey = 'E',
    disabled = true,
    onPressed = function(self)
        local vehicle = cache.vehicle
        if not vehicle or cache.seat ~= -1 or not IsThisModelABoat(GetEntityModel(vehicle)) then return end

        if GetEntitySpeed(vehicle) > 3.0 then return end

        local anchored = Entity(vehicle).state.isAnchored or false
        local netId = NetworkGetNetworkIdFromEntity(vehicle)

        lib.callback.await('anchor:toggle', 2500, netId, not anchored)
    end
})

lib.onCache('seat', function(seat)
    if (not seat or seat ~= -1) and textUI then
        keybind:disable(true)
        return reset()
    end

    if not cache.vehicle then
        keybind:disable(true)
        return reset()
    end

    if not IsThisModelABoat(GetEntityModel(cache.vehicle)) then
        keybind:disable(true)
        return reset()
    end

    show(cache.vehicle)
    keybind:disable(false)
end)

qbx.entityStateHandler('isAnchored', function (entity, netId, value, bagName)
    SetBoatAnchor(entity, value)
    SetBoatFrozenWhenAnchored(entity, value)
    show(entity)
end)