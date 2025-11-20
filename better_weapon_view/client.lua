lib.onCache('weapon', function(weapon)
    if not weapon then return end
    CreateThread(function()
        local setpov = false
        while cache.weapon do
            if IsPlayerFreeAiming(cache.playerId) then
                DisableControlAction(0, 0, true)
                local currentMode = GetFollowPedCamViewMode()
                if currentMode ~= 4 and currentMode ~= 0 then
                    SetFollowPedCamViewMode(0)
                end
                if not setpov and IsDisabledControlJustPressed(0, 0) then
                    setpov = true
                    SetFollowPedCamViewMode(4)
                elseif setpov and IsDisabledControlJustPressed(0, 0) then
                    setpov = false
                    SetFollowPedCamViewMode(0)
                end
            else
                setpov = false
                EnableControlAction(0, 0, true)
            end
            Wait(0)
        end
    end)
end)