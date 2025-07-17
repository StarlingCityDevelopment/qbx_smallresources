CreateThread(function()
    while true do
        Wait(3000)
        local weather = GlobalState["currentweather"] or "CLEAR"
        if weather:upper() == "THUNDER" or weather:upper() == "STORM" then
            ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.3)
            SetWind(100.0)
        else
            SetWind(0.0)
            StopGameplayCamShaking(false)
        end
    end
end)