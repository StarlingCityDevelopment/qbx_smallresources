lib.onCache('weapon', function(weapon)
    Wait(5)
    if not weapon then return end

    CreateThread(function()
        local setpov = false

        while cache.weapon ~= weapon do Wait(1) end

        while cache.weapon do
            if IsPlayerFreeAiming(cache.playerId) then
                DisableControlAction(0, 0, true)

                if (GetFollowPedCamViewMode() == 4 or GetFollowPedCamViewMode() == 0) then goto continue end

                SetFollowPedCamViewMode(0)

                ::continue::
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