local last = 0

local function fadeOut()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    DoScreenFadeIn(500)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        if (GetVehiclePedIsIn(PlayerPedId(), false) == args[1]) and args[3] > 1109990000 then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local health = GetVehicleBodyHealth(vehicle)
            if health ~= last then
                ShakeGameplayCam("MEDIUM_EXPLOSION_SHAKE", ((1109999999 / args[3]) * 10 / 225.0))
                Wait(150)
                if args[3] > 1109990000 then fadeOut() end
            end
            last = health
        end
    end
end)