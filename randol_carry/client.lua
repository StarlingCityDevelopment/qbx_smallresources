local plyState = LocalPlayer.state

lib.addKeybind({
    name = "cancel_carry",
    description = locale("carry.cancel_description"),
    defaultKey = "X",
    onPressed = function()
        if plyState.isCarrying then
            TriggerServerEvent("randol_carry:stopCarry")
        end
    end,
})

local function carryingLoop(id)
    if plyState.isCarrying then
        return
    end

    local anim, dict = "fin_c2_mcs_1_camman", "missfinale_c2mcs_1"

    Wait(0)

    while plyState.isCarrying do
        local player = GetPlayerFromServerId(id)
        local ped = player > 0 and GetPlayerPed(player)

        if not ped or not DoesEntityExist(ped) then
            TriggerServerEvent("randol_carry:stopCarry")
            break
        end

        if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
            lib.playAnim(cache.ped, dict, anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        end

        lib.showTextUI(locale("carry.in_progress"), {
            icon = "fas fa-person-carry",
        })

        Wait(100)
    end

    lib.hideTextUI()
    DetachEntity(cache.ped, true, false)
    StopAnimTask(cache.ped, dict, anim, 2.5)
end

local function beingCarriedLoop(id)
    if plyState.beingCarried then
        return
    end

    local anim, dict = "firemans_carry", "nm"

    Wait(0)

    while plyState.beingCarried do
        local player = GetPlayerFromServerId(id)
        local ped = player > 0 and GetPlayerPed(player)

        if not ped or not DoesEntityExist(ped) then
            break
        end

        if not IsEntityAttachedToEntity(cache.ped, ped) then
            AttachEntityToEntity(
                cache.ped,
                ped,
                0,
                0.27,
                0.15,
                0.63,
                0.5,
                0.5,
                180,
                false,
                false,
                false,
                false,
                2,
                false
            )
        end

        if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
            lib.playAnim(cache.ped, dict, anim, 8.0, -8.0, -1, 33, 0.0, false, false, false)
        end

        Wait(100)
    end

    DetachEntity(cache.ped, true, false)
    StopAnimTask(cache.ped, dict, anim, 2.5)
end

RegisterNetEvent("randol_carry:receiveRequest", function(carrierId, carrierName)
    local result = lib.alertDialog({
        header = locale("carry.request_header"),
        content = locale("carry.request_message", carrierName),
        centered = true,
        cancel = true,
        labels = { confirm = locale("carry.request_accept"), cancel = locale("carry.request_deny") },
    })

    TriggerServerEvent("randol_carry:respondRequest", carrierId, result == "confirm")
end)

exports.ox_target:addGlobalPlayer({
    {
        name = "randol_carry",
        icon = "fas fa-person-walking",
        label = locale("carry.player_label"),
        distance = 2.0,
        onSelect = function(data)
            local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(data.entity))
            if targetServerId == cache.serverId then
                return
            end
            TriggerServerEvent("randol_carry:requestCarry", targetServerId)
        end,
        canInteract = function(entity)
            if not entity or not DoesEntityExist(entity) then
                return false
            end
            local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(entity))
            return not plyState.isCarrying and not plyState.beingCarried and targetServerId ~= cache.serverId
        end,
    },
})

AddStateBagChangeHandler("isCarrying", ("player:%s"):format(cache.serverId), function(_, _, value)
	if value then
		carryingLoop(value)
	end
end)

AddStateBagChangeHandler("beingCarried", ("player:%s"):format(cache.serverId), function(_, _, value)
	if value then
		beingCarriedLoop(value)
	end
end)