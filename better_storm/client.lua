local isStormActive = false

local function HandleShake()
    if not isStormActive then return end
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.15)
    SetWind(100.0)
    SetTimeout(math.random(10000, 25000), function()
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