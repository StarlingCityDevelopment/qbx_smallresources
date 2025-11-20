AddStateBagChangeHandler('weather', 'global', function(_, _, value)
    if value then
        if value.weather:upper() == "THUNDER" or value.weather:upper() == "STORM" then
            SetTimeout(0, function()
                CreateThread(function()
                    while true do
                        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
                        SetWind(100.0)
                        Wait(5000)
                    end
                end)
            end)
        else
            SetWind(0.0)
            StopGameplayCamShaking(false)
        end
    else
        SetWind(0.0)
        StopGameplayCamShaking(false)
    end
end)