local isStormActive = false

local function HandleShake()
    if not isStormActive then return end
    local interior = GetInteriorFromEntity(PlayerPedId())
    if not interior or interior == 0 then
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.10)
        SetWind(100.0)
    end
    SetTimeout(math.random(25000, 45000), function()
        HandleShake()
    end)
end

AddStateBagChangeHandler('weather', 'global', function(_, _, value)
    if value then
        if value.weather:upper() == "THUNDER" or value.weather:upper() == "STORM" then
            isStormActive = true
            HandleShake()
        else
            isStormActive = false
            SetWind(0.0)
            StopGameplayCamShaking(false)
        end
    else
        isStormActive = false
        SetWind(0.0)
        StopGameplayCamShaking(false)
    end
end)