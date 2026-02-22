local cam = 0
local isInsideTrunk = false
local currentVehicle = nil

local disabledTrunk = {
    [`penetrator`] = "penetrator",
    [`vacca`] = "vacca",
    [`monroe`] = "monroe",
    [`turismor`] = "turismor",
    [`osiris`] = "osiris",
    [`comet`] = "comet",
    [`ardent`] = "ardent",
    [`jester`] = "jester",
    [`nero`] = "nero",
    [`nero2`] = "nero2",
    [`vagner`] = "vagner",
    [`infernus`] = "infernus",
    [`zentorno`] = "zentorno",
    [`comet2`] = "comet2",
    [`comet3`] = "comet3",
    [`comet4`] = "comet4",
    [`bullet`] = "bullet",
}

local function TrunkCam(bool)
    local vehicle = GetEntityAttachedTo(cache.ped)
    local drawPos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -5.5, 0)
    local vehHeading = GetEntityHeading(vehicle)
    if bool then
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(cam) then
            DestroyCam(cam, false)
            cam = 0
        end

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(cam, true)
        SetCamCoord(cam, drawPos.x, drawPos.y, drawPos.z + 2)
        SetCamRot(cam, -2.5, 0.0, vehHeading, 0.0)
        RenderScriptCams(true, false, 0, true, true)
    else
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(cam) then
            DestroyCam(cam, false)
            cam = 0
        end
    end
end

local function canHideInTrunk(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if isInsideTrunk then return false end

    local model = GetEntityModel(vehicle)
    if disabledTrunk[model] then return false end

    local vehClass = GetVehicleClass(vehicle)
    if vehClass == 8 or vehClass == 13 or vehClass == 14 or vehClass == 15 or vehClass == 16 or vehClass == 21 then
        return false
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 2 then
        return false
    end

    local trunkBone = GetEntityBoneIndexByName(vehicle, 'boot')
    if trunkBone == -1 then return false end

    if Entity(vehicle).state.trunkOccupied then return false end

    return true
end

local function leaveTrunk()
    if not isInsideTrunk or not currentVehicle then return end

    local vehicle = currentVehicle
    local ped = cache.ped

    if DoesEntityExist(vehicle) then
        if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
            SetVehicleDoorOpen(vehicle, 5, false, false)
            Wait(500)
        end
    end

    isInsideTrunk = false
    currentVehicle = nil

    if DoesEntityExist(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('cdx_hideintrunk:server:setTrunkOccupied', netId, false)
    end

    TrunkCam(false)

    SetEntityCollision(ped, true, true)
    DetachEntity(ped, true, true)
    SetEntityVisible(ped, true, false)
    ClearPedTasks(ped)

    if DoesEntityExist(vehicle) then
        local dropCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.0, 0.0)
        SetEntityCoords(ped, dropCoords.x, dropCoords.y, dropCoords.z, false, false, false, false)
    else
        local dropCoords = GetEntityCoords(ped)
        SetEntityCoords(ped, dropCoords.x, dropCoords.y, dropCoords.z, false, false, false, false)
    end

    if DoesEntityExist(vehicle) then
        Wait(250)
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

local function enterTrunk(vehicle)
    local ped = cache.ped
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 2 then
        lib.notify({ title = locale('hide_in_trunk.vehicle_locked'), type = 'error' })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local success = lib.callback.await('cdx_hideintrunk:server:tryOccupyTrunk', 200, netId)

    if not success then
        lib.notify({ title = locale('hide_in_trunk.trunk_occupied'), type = 'error' })
        return
    end

    isInsideTrunk = true
    currentVehicle = vehicle

    if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
        SetVehicleDoorOpen(vehicle, 5, false, false)
        Wait(350)
    end

    AttachEntityToEntity(ped, vehicle, -1, 0.0, -2.2, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
    lib.playAnim(ped, 'timetable@floyd@cryingonbed@base', 'base')

    TrunkCam(true)

    Wait(1500)
    SetVehicleDoorShut(vehicle, 5, false)

    CreateThread(function()
        while isInsideTrunk do
            local sleep = 1000
            local currentVehicle = GetEntityAttachedTo(cache.ped)
            if DoesEntityExist(cam) then
                sleep = 0
                local drawPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 0, -5.5, 0)
                local vehHeading = GetEntityHeading(currentVehicle)
                SetCamRot(cam, -2.5, 0.0, vehHeading, 0.0)
                SetCamCoord(cam, drawPos.x, drawPos.y, drawPos.z + 2)
            end
            Wait(sleep)
        end
    end)

    CreateThread(function()
        lib.showTextUI(locale('hide_in_trunk.controls'))

        while isInsideTrunk do
            Wait(0)

            local currentVehicleValid = DoesEntityExist(currentVehicle) and not IsPedDeadOrDying(ped)
            if not currentVehicleValid then
                leaveTrunk()
                break
            end

            SetEntityCollision(ped, false, false)

            if GetVehicleDoorAngleRatio(currentVehicle, 5) < 0.9 then
                SetEntityVisible(ped, false, false)
            else
                if not IsEntityPlayingAnim(ped, 'timetable@floyd@cryingonbed@base', 3) then
                    lib.playAnim(ped, 'timetable@floyd@cryingonbed@base', 'base')
                    SetEntityVisible(ped, true, false)
                end
            end

            DisableControlAction(0, 75, true)
            DisableControlAction(27, 75, true)

            if IsControlJustReleased(0, 38) then
                leaveTrunk()
            elseif IsControlJustReleased(0, 74) then
                local angle = GetVehicleDoorAngleRatio(currentVehicle, 5)
                if angle < 0.9 then
                    SetVehicleDoorOpen(currentVehicle, 5, false, false)
                else
                    SetVehicleDoorShut(currentVehicle, 5, false)
                end
            end
        end

        lib.hideTextUI()
    end)
end

CreateThread(function()
    local options = {
        {
            name = 'cdx_hide_in_trunk',
            icon = 'fa-solid fa-car-side',
            label = locale('hide_in_trunk.label'),
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                return canHideInTrunk(entity)
            end,
            onSelect = function(data)
                enterTrunk(data.entity)
            end,
            bones = { 'boot' }
        }
    }
    exports.ox_target:addGlobalVehicle(options)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        TrunkCam(false)
    end
end)