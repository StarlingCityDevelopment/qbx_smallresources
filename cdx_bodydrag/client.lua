local playerState = LocalPlayer.state
local isDragged = false
local isDragging = false

local function isTargetDead(entity)
    local id = NetworkGetPlayerIndexFromPed(entity)
    return lib.callback.await('cdx:bodydrag:server:isPlayerDead', false, GetPlayerServerId(id))
end

local function dragPlayer(ped, state)
    local id = NetworkGetPlayerIndexFromPed(ped)
    TriggerServerEvent('cdx:bodydrag:server:setDragEscort', GetPlayerServerId(id), state)
end

local function setDragged(draggerId)
    local dict = 'combat@drag_ped@'
    local anim = 'injured_drag_ped'

    lib.requestAnimDict(dict)

    local draggerPlayer = GetPlayerFromServerId(draggerId)
    local draggerPed = draggerPlayer ~= -1 and GetPlayerPed(draggerPlayer) or nil

    if draggerPed then
        AttachEntityToEntity(cache.ped, draggerPed, 11816, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2,
            true)
    end

    while isDragged do
        draggerPlayer = GetPlayerFromServerId(draggerId)
        draggerPed = draggerPlayer ~= -1 and GetPlayerPed(draggerPlayer) or nil

        if draggerPed and DoesEntityExist(draggerPed) then
            SetEntityNoCollisionEntity(cache.ped, draggerPed, true)

            if not IsEntityAttachedToEntity(cache.ped, draggerPed) then
                AttachEntityToEntity(cache.ped, draggerPed, 11816, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, false,
                    false, 2, true)
            end
        end

        if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
            lib.playAnim(cache.ped, dict, anim)
        end

        Wait(0)
    end

    DetachEntity(cache.ped, true, false)
    ClearPedTasks(cache.ped)
    playerState:set('isDragged', false, true)
end

local function setDragging(targetId)
    local dict = 'combat@drag_ped@'
    local anim = 'injured_drag_plyr'

    lib.requestAnimDict(dict)
    lib.showTextUI('[E] Arrêter de traîner')

    local currentViewMode = GetFollowPedCamViewMode()
    SetFollowPedCamViewMode(4)

    while isDragging do
        local targetPlayer = GetPlayerFromServerId(targetId)
        local targetPed = targetPlayer ~= -1 and GetPlayerPed(targetPlayer) or nil

        if targetPed and DoesEntityExist(targetPed) then
            SetEntityNoCollisionEntity(cache.ped, targetPed, true)
        end

        if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then
            lib.playAnim(cache.ped, dict, anim, 8.0, -8.0, -1, 49)
        end

        if GetFollowPedCamViewMode() ~= 4 then
            SetFollowPedCamViewMode(4)
        end

        if IsControlJustPressed(0, 38) then
            TriggerServerEvent('cdx:bodydrag:server:setDragEscort', targetId, false)
            Wait(100)
        end

        Wait(0)
    end

    SetFollowPedCamViewMode(currentViewMode)

    ClearPedTasks(cache.ped)
    lib.hideTextUI()
    playerState:set('isDragging', false, true)
end

AddStateBagChangeHandler('isDragged', ('player:%s'):format(cache.serverId), function(_, _, value)
    isDragged = value
    if value then
        CreateThread(function()
            setDragged(value)
        end)
    end
end)

AddStateBagChangeHandler('isDragging', ('player:%s'):format(cache.serverId), function(_, _, value)
    isDragging = value
    if value then
        CreateThread(function()
            setDragging(value)
        end)
    end
end)

AddStateBagChangeHandler('dead', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value and isDragging then
        TriggerServerEvent('cdx:bodydrag:server:setDragEscort', isDragging, false)
    end
end)

CreateThread(function()
    Wait(500)

    local state = playerState.isDragged
    if state then
        isDragged = state
        setDragged(state)
    end

    local draggingState = playerState.isDragging
    if draggingState then
        isDragging = draggingState
        setDragging(draggingState)
    end
end)

exports.ox_target:addGlobalPlayer({
    {
        name = 'cdx:bodydrag:attach',
        icon = 'fas fa-hands-bound',
        label = 'Traîner la personne',
        canInteract = function(entity)
            return not playerState.invBusy and not IsEntityAttachedToEntity(entity, cache.ped) and
                not IsPedInAnyVehicle(entity, true)
        end,
        onSelect = function(data)
            if isTargetDead(data.entity) then
                dragPlayer(data.entity, true)
            else
                lib.notify({ type = 'error', description = 'Player is not conscious.' })
            end
        end
    },
    {
        name = 'cdx:bodydrag:dettach',
        icon = 'fas fa-hands-bound',
        label = 'Arrêter de traîner',
        canInteract = function(entity)
            return not playerState.invBusy and IsEntityAttachedToEntity(entity, cache.ped)
        end,
        onSelect = function(data)
            dragPlayer(data.entity, false)
        end
    },
})