local handsup = false

local handsupDict = "missminuteman_1ig_2"
local handsupAnim = "handsup_enter"

local function canExecuteAction()
    return not IsPedRagdoll(cache.ped) and
           not LocalPlayer.state.invBusy and
           LocalPlayer.state.dead and
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

            if cache.ped then DisableControlAction(0, 59, true) end

            if not IsEntityPlayingAnim(cache.ped, handsupDict, handsupAnim, 3) then
                lib.playAnim(cache.ped, handsupDict, handsupAnim, 8.0, 8.0, -1, 50, 0, false, false, false)
            end
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
    end,
    onReleased = function()
        if IsEntityPlayingAnim(cache.ped, handsupDict, handsupAnim, 3) then
            handsup = false
            ClearPedTasks(cache.ped)
        end
    end
})