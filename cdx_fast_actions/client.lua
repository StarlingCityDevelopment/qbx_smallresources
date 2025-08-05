local handsup = false

local handsupDict = "missminuteman_1ig_2"
local handsupAnim = "handsup_enter"

local function canExecuteAction()
    return not IsPedRagdoll(cache.ped) and
        not LocalPlayer.state.invBusy and
        not LocalPlayer.state.isDead and
        not LocalPlayer.state.cuffed and
        not LocalPlayer.state.escorted and
        -- not exports['rcore_prison']:IsPrisoner() and
        not IsPedFalling(cache.ped) and
        not IsPedSwimming(cache.ped) and
        not IsPedClimbing(cache.ped) and
        not IsPedInParachuteFreeFall(cache.ped)
end

local function handsUpThread()
    handsup = not handsup

    lib.playAnim(cache.ped, handsupDict, handsupAnim, 8.0, 8.0, -1, 50, 0, false, false, false)

    CreateThread(function()
        while handsup and canExecuteAction() do
            Wait(0)

            DisablePlayerFiring(cache.ped, true)

            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            if cache.vehicle then DisableControlAction(0, 59, true) end

            if not IsEntityPlayingAnim(cache.ped, handsupDict, handsupAnim, 3) then
                lib.playAnim(cache.ped, handsupDict, handsupAnim, 8.0, 8.0, -1, 50, 0, false, false, false)
            end
        end

        if IsEntityPlayingAnim(cache.ped, handsupDict, handsupAnim, 3) then
            handsup = false
            ClearPedTasks(cache.ped)
        end
    end)
end

lib.addKeybind({
    name = 'cdx_fast_actions_hands_up',
    description = 'Pressez SHIFT + X pour lever les mains',
    defaultKey = 'X',
    onPressed = function()
        if IsControlPressed(1, 21) and canExecuteAction() then
            handsUpThread()
        end
    end
})

lib.addKeybind({
    name = 'cdx_fast_actions_tackle',
    description = 'Pressez SHIFT + E pour plaquer',
    defaultKey = 'E',
    onPressed = function(self)
        if IsControlPressed(1, 21) and not cache.vehicle and canExecuteAction() and QBX.PlayerData.job.type == 'leo' then
            local coords = GetEntityCoords(cache.ped)
            local targetId, targetPed, _ = lib.getClosestPlayer(coords, 1.6, false)
            if not targetPed then return end
            if IsPedInAnyVehicle(targetPed, true) then return end
            self:disable(true)
            TriggerServerEvent('cdx:fastactions:server:TacklePlayer', GetPlayerServerId(targetId))
            lib.playAnim(cache.ped, 'swimming@first_person@diving', 'dive_run_fwd_-45_loop', 3.0, 3.0, -1, 49, 0, false, false, false)
            Wait(250)
            ClearPedTasks(cache.ped)
            SetPedToRagdoll(cache.ped, 150, 150, 0, false, false, false)
            RemoveAnimDict('swimming@first_person@diving')
            SetTimeout(1000, function ()
                self:disable(false)
            end)
        end
    end
})

RegisterNetEvent('cdx:fastactions:client:GetTackled', function()
    SetPedToRagdoll(cache.ped, 7000, 7000, 0, false, false, false)
end)