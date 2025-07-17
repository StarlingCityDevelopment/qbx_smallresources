local playerState = LocalPlayer.state
local isDragged = playerState.isDragged
local isDragging = playerState.isDragging

local Wait = Wait
local ClearPedTasks = ClearPedTasks
local RemoveAnimDict = RemoveAnimDict
local GetAnimDuration = GetAnimDuration
local TaskPlayAnim = TaskPlayAnim
local IsEntityPlayingAnim = IsEntityPlayingAnim
local AttachEntityToEntity = AttachEntityToEntity
local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local IsEntityAttached = IsEntityAttached
local DetachEntity = DetachEntity
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local GetPlayerFromServerId = GetPlayerFromServerId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local TriggerServerEvent = TriggerServerEvent
local AddStateBagChangeHandler = AddStateBagChangeHandler
local CreateThread = CreateThread

local function isTargetDead(entity)
    local id = NetworkGetPlayerIndexFromPed(entity)
    return lib.callback.await('cdx:bodydrag:server:isPlayerDead', false, GetPlayerServerId(id))
end

local function dragPlayer(ped, state)
    local id = NetworkGetPlayerIndexFromPed(ped)
    TriggerServerEvent('cdx:bodydrag:server:setDragEscort', GetPlayerServerId(id), state)
end

local function loadAnimation(dict, anim)
    lib.requestAnimDict(dict)
    local duration = GetAnimDuration(dict, anim)
    TaskPlayAnim(cache.ped, dict, anim, 8.0, 8.0, duration, 1, 0.0, false, false, false)
    Wait(duration)
end

local function setDragged(serverId)
    local dict = 'combat@drag_ped@'
    local intro = 'injured_pickup_back_ped'
    local loop = 'injured_drag_ped'
    local outro = 'injured_putdown_ped'

    loadAnimation(dict, intro)

    while isDragged do
        local player = GetPlayerFromServerId(serverId)
        local ped = player > 0 and GetPlayerPed(player)

        if not ped then break end

        if not IsEntityAttachedToEntity(cache.ped, ped) then
            AttachEntityToEntity(cache.ped, ped, 11816, 0.25, 0.48, 0.0, 0.0, 0.0, 0.0, false, false, true, true, 2, true)
        end

        if not IsEntityPlayingAnim(cache.ped, dict, loop, 3) then
            TaskPlayAnim(cache.ped, dict, loop, 8.0, -8, -1, 1, 0.0, false, false, false)
        end

        Wait(0)
    end

    loadAnimation(dict, outro)
    RemoveAnimDict(dict)
    ClearPedTasks(cache.ped)

    playerState:set('isDragged', false, true)
end

local function setDragging()
    local dict = 'combat@drag_ped@'
    local intro = 'injured_pickup_back_plyr'
    local loop = 'injured_drag_plyr'
    local outro = 'injured_putdown_plyr'

    loadAnimation(dict, intro)

    while isDragging do
        if not IsEntityPlayingAnim(cache.ped, dict, loop, 3) then
            TaskPlayAnim(cache.ped, dict, loop, 8.0, 8.0, -1, 51, 0.0, false, false, false)
        end
        Wait(0)
    end

    loadAnimation(dict, outro)
    RemoveAnimDict(dict)
    ClearPedTasks(cache.ped)

    playerState:set('isDragging', false, true)
end

AddStateBagChangeHandler('isDragged', ('player:%s'):format(cache.serverId), function(_, _, value)
    isDragged = value

    if IsEntityAttached(cache.ped) then
        DetachEntity(cache.ped, true, false)
    end

    if value then
        setDragged(value)
    end
end)

AddStateBagChangeHandler('isDragging', ('player:%s'):format(cache.serverId), function(_, _, value)
    isDragging = value
    if value then
        setDragging()
    end
end)

if isDragged then
    CreateThread(function()
        setDragged(isDragged)
    end)
end

if isDragging then
    CreateThread(function()
        setDragging()
    end)
end

exports.ox_target:addGlobalPlayer({
    {
        name = 'cdx:bodydrag:attach',
        icon = 'fas fa-hands-bound',
        label = locale('actions.drag_player'),
        canInteract = function(entity)
            return not playerState.invBusy and not IsEntityAttachedToEntity(entity, cache.ped) and isTargetDead(entity)
        end,
        onSelect = function(data)
            dragPlayer(data.entity, true)
        end
    },
    {
        name = 'cdx:bodydrag:dettach',
        icon = 'fas fa-hands-bound',
        label = locale('actions.stop_dragging'),
        canInteract = function(entity)
            return not playerState.invBusy and IsEntityAttachedToEntity(entity, cache.ped) and isTargetDead(entity)
        end,
        onSelect = function(data)
            dragPlayer(data.entity, false)
        end
    },
})