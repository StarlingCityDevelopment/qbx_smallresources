local pendingRequests = {}

local function notify(src, text, nType)
    lib.notify(src, {
        title = locale("carry.notify_title"),
        description = text,
        duration = 5000,
        type = nType,
        position = "center-right",
    })
end

local function startCarry(carrierId, targetId)
    local carrierState = Player(carrierId).state
    local targetState = Player(targetId).state
    carrierState:set("isCarrying", targetId, true)
    targetState:set("beingCarried", carrierId, true)
end

local function stopCarry(src)
    if not GetPlayerName(src) then
        return
    end
    local state = Player(src).state

    if state.isCarrying then
        local targetId = state.isCarrying
        state:set("isCarrying", nil, true)
        if GetPlayerName(targetId) then
            Player(targetId).state:set("beingCarried", nil, true)
        end
    elseif state.beingCarried then
        local carrierId = state.beingCarried
        state:set("beingCarried", nil, true)
        if GetPlayerName(carrierId) then
            Player(carrierId).state:set("isCarrying", nil, true)
        end
    end
end

RegisterNetEvent("randol_carry:requestCarry", function(targetServerId)
    local src = source
    local ped = GetPlayerPed(src)
    local plyState = Player(src).state

    if plyState.beingCarried then
        return notify(src, locale("carry.error_being_carried"), "error")
    end

    if plyState.isCarrying then
        return notify(src, locale("carry.error_already_carrying"), "error")
    end

    if GetVehiclePedIsIn(ped, false) ~= 0 then
        return notify(src, locale("carry.error_carrier_in_vehicle"), "error")
    end

    if not GetPlayerName(targetServerId) then
        return notify(src, locale("carry.error_invalid_target"), "error")
    end

    local targetPed = GetPlayerPed(targetServerId)
    local srcCoords = GetEntityCoords(ped)
    local targetCoords = GetEntityCoords(targetPed)

    if #(srcCoords - targetCoords) > 3.0 then
        return notify(src, locale("carry.error_target_too_far"), "error")
    end

    if GetVehiclePedIsIn(targetPed, false) ~= 0 then
        return notify(src, locale("carry.error_target_in_vehicle"), "error")
    end

    local targetState = Player(targetServerId).state
    if targetState.beingCarried or targetState.isCarrying then
        return notify(src, locale("carry.error_target_busy"), "error")
    end

    pendingRequests[targetServerId] = src
    TriggerClientEvent("randol_carry:receiveRequest", targetServerId, src, GetPlayerName(src))
end)

RegisterNetEvent("randol_carry:respondRequest", function(carrierId, accepted)
    local src = source

    if pendingRequests[src] ~= carrierId then
        return
    end
    pendingRequests[src] = nil

    if not accepted then
        notify(carrierId, locale("carry.error_request_denied"), "error")
        return
    end

    if not GetPlayerName(carrierId) then
        return
    end

    local carrierState = Player(carrierId).state
    local targetState = Player(src).state

    if carrierState.isCarrying or carrierState.beingCarried then
        notify(src, locale("carry.error_carrier_unavailable"), "error")
        return
    end

    if targetState.beingCarried or targetState.isCarrying then
        notify(carrierId, locale("carry.error_target_unavailable"), "error")
        return
    end

    startCarry(carrierId, src)
end)

RegisterNetEvent("randol_carry:stopCarry", function()
    stopCarry(source)
end)

AddEventHandler("playerDropped", function()
    local src = source

    pendingRequests[src] = nil
    for targetId, carrierId in pairs(pendingRequests) do
        if carrierId == src then
            pendingRequests[targetId] = nil
        end
    end

    stopCarry(src)
end)

exports("startCarry", function(carrierId, targetId)
    startCarry(carrierId, targetId)
end)

exports("stopCarry", function(src)
    stopCarry(src)
end)

exports("getCarryState", function(src)
    local state = Player(src).state
    return {
        isCarrying = state.isCarrying,
        beingCarried = state.beingCarried,
    }
end)
