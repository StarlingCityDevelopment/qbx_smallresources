local config = require 'tactical_lite.config'

local GMath = {}

function GMath.GetCameraDirection()
    local rot = GetGameplayCamRot(2)
    local tZ, tX = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(tX))
    return vector3(-math.sin(tZ) * num, math.cos(tZ) * num, math.sin(tX))
end

local function SmootherStep(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local Lean = {}
Lean.cam = nil
Lean.currentPeek = 0 -- 0: None, 1: Right, 2: Left
Lean.f = 0.0
Lean.lastSyncState = { mode = "NONE", crouch = false }

local function GetCameraPositionX()
    local viewMode = GetFollowPedCamViewMode()
    local multiplier = Lean.currentPeek == 1 and 1.0 or -1.0
    local extraRight = Lean.currentPeek == 1 and config.Lean.TPV.extraRightOffset or 0

    if viewMode == 0 then
        return (config.Lean.TPV.lateralOffsetClose + extraRight) * multiplier
    elseif viewMode == 1 then
        return (config.Lean.TPV.lateralOffsetMedium + extraRight) * multiplier
    elseif viewMode == 2 then
        return (config.Lean.TPV.lateralOffsetFar + extraRight) * multiplier
    end
    return 0.0
end

local function GetCameraPositionTranslation(gameplayCamCoords, pedCoords)
    local x = GetCameraPositionX()
    local z = config.Lean.TPV.verticalOffset
    local forward = GetEntityForwardVector(PlayerPedId())
    local camToPed = gameplayCamCoords - pedCoords
    local yDist = (forward.x * camToPed.x) + (forward.y * camToPed.y)
    return vector3(x, yDist, z)
end

local function CheckCollision(ped, targetPos)
    local pedPos = GetEntityCoords(ped)
    local raycast = StartShapeTestCapsule(pedPos.x, pedPos.y, pedPos.z, targetPos.x, targetPos.y, targetPos.z, 0.2, 511,
        ped, 4)
    local _, hit = GetShapeTestResult(raycast)
    return hit == 1
end

local function CleanupCameraImmediate()
    if Lean.cam then
        RenderScriptCams(false, false, 0, true, true)
        if IsCamActive(Lean.cam) then
            SetCamActive(Lean.cam, false)
        end
        DestroyCam(Lean.cam, false)
        Lean.cam = nil
    end
    Lean.currentPeek = 0
    Lean.f = 0.0
end

local function DrawTacticalReticle()
    -- DrawRect(0.5, 0.5, 0.0030, 0.0030, 255, 255, 255, 200)
end

function Lean.Update(ped, isAiming, qPressed, ePressed)
    local viewMode = GetFollowPedCamViewMode()
    if viewMode == 4 then
        if Lean.f > 0 or Lean.cam then CleanupCameraImmediate() end
        return
    end

    if Lean.f > 0 then DrawTacticalReticle() end
    local isCrouching = IsPedDucking(ped)

    local targetPeek = 0
    if isAiming then
        if ePressed then
            targetPeek = 1
        elseif qPressed then
            targetPeek = 2
        end
    end

    if Lean.f <= 0.0 then
        if Lean.currentPeek ~= targetPeek then
            Lean.currentPeek = targetPeek
            if Lean.currentPeek ~= 0 then
                local mode = (Lean.currentPeek == 1) and "RIGHT" or "LEFT"
                local anim = isCrouching and config.Lean.Anims[mode].low or config.Lean.Anims[mode].high
                lib.requestAnimDict(anim.dict)
                TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
        end
    else
        if targetPeek ~= 0 and targetPeek ~= Lean.currentPeek then
            targetPeek = 0
        end
    end

    if not isAiming then targetPeek = 0 end

    local dt = GetFrameTime()
    local duration = 0.25
    local speed = 1.0 / duration

    if targetPeek ~= 0 and Lean.currentPeek == targetPeek then
        Lean.f = math.min(Lean.f + dt * speed, 1.0)
    else
        Lean.f = math.max(Lean.f - dt * speed, 0.0)
    end

    local currentModeStr = "NONE"
    if Lean.currentPeek == 1 then
        currentModeStr = "RIGHT"
    elseif Lean.currentPeek == 2 then
        currentModeStr = "LEFT"
    end

    if targetPeek == 0 then currentModeStr = "NONE" end

    if Lean.lastSyncState.mode ~= currentModeStr or Lean.lastSyncState.crouch ~= isCrouching then
        Lean.lastSyncState = { mode = currentModeStr, crouch = isCrouching }
        LocalPlayer.state:set('TacticalLean', Lean.lastSyncState, true)
        if currentModeStr == "NONE" then ClearPedSecondaryTask(ped) end
    end

    if Lean.f > 0.001 then
        if not Lean.cam then
            local rot = GetGameplayCamRot(2)
            local coords = GetGameplayCamCoord()
            Lean.cam = CreateCamWithParams(
                "DEFAULT_SCRIPTED_CAMERA",
                coords.x, coords.y, coords.z,
                rot.x, rot.y, rot.z,
                GetGameplayCamFov(),
                true, 2
            )
            SetCamActive(Lean.cam, true)
            RenderScriptCams(true, false, 0, true, true)
        end

        local gameplayCamCoords = GetGameplayCamCoord()
        local gameplayCamRot = GetGameplayCamRot(2)
        local pedCoords = GetEntityCoords(ped)

        local posTrans = GetCameraPositionTranslation(gameplayCamCoords, pedCoords)
        local targetLeanCoords = GetOffsetFromEntityInWorldCoords(ped, posTrans.x, posTrans.y, posTrans.z)

        local hitLean = CheckCollision(ped, targetLeanCoords)
        if hitLean then
            targetLeanCoords = gameplayCamCoords
        end

        local easeV = SmootherStep(Lean.f)
        local newPos = Lerp(gameplayCamCoords, targetLeanCoords, easeV)

        local targetRoll = (Lean.currentPeek == 1 and 1.0 or -1.0) * config.Lean.TPV.cameraRoll
        local currentRoll = Lerp(0.0, targetRoll, easeV)

        SetCamCoord(Lean.cam, newPos.x, newPos.y, newPos.z)
        SetCamRot(Lean.cam, gameplayCamRot.x, gameplayCamRot.y + currentRoll, gameplayCamRot.z, 2)
        SetCamFov(Lean.cam, GetGameplayCamFov())
    elseif Lean.cam then
        CleanupCameraImmediate()
    end
end

AddStateBagChangeHandler('TacticalLean', nil, function(bagName, key, value, _unused, replicated)
    local ply = GetPlayerFromStateBagName(bagName)
    if not ply or ply == PlayerId() then return end
    local remotePed = GetPlayerPed(ply)
    if not DoesEntityExist(remotePed) then return end

    if not value or value.mode == "NONE" then
        ClearPedSecondaryTask(remotePed)
    else
        local animData = value.crouch and config.Lean.Anims[value.mode].low or config.Lean.Anims[value.mode].high
        lib.requestAnimDict(animData.dict)
        TaskPlayAnim(remotePed, animData.dict, animData.clip, 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end)

local Grenade = {}
Grenade.lastThrowTime = 0
Grenade.isThrowing = false
local R_HAND_BONE = 28422
local ANIM_DICT = "weapons@projectile@aim_throw_rifle"
local ANIM_NAME = "aim_throw_m"

local function GetBestThrowable()
    for _, cfg in ipairs(config.QuickThrow.Throwables) do
        local count = exports.ox_inventory:Search('count', cfg.item)
        if count > 0 then return cfg end
    end
    return nil
end

local function FireNetworkedProjectile(ped, hash, speed)
    local camDir = GMath.GetCameraDirection()
    local spawnPos = GetPedBoneCoords(ped, R_HAND_BONE, 0.0, 0.0, 0.0)
    local finalSpawn = spawnPos + (camDir * 0.8)
    local finalTarget = finalSpawn + (camDir * 50.0)

    ShootSingleBulletBetweenCoords(
        finalSpawn.x, finalSpawn.y, finalSpawn.z,
        finalTarget.x, finalTarget.y, finalTarget.z,
        0, true, hash, ped, true, false, speed
    )
end

local function ProcessQuickThrow()
    local ped = PlayerPedId()
    if Grenade.isThrowing or not config.QuickThrow.Enabled then return end
    if not IsPlayerFreeAiming(PlayerId()) or IsPedInAnyVehicle(ped, false) then return end

    local throwable = GetBestThrowable()
    if not throwable then
        return lib.notify({ type = 'error', description = 'ไม่มีอาวุธขว้างในตัว!' })
    end

    local now = GetGameTimer()
    if now - Grenade.lastThrowTime < config.QuickThrow.Cooldown then return end

    Grenade.isThrowing = true
    Grenade.lastThrowTime = now

    CreateThread(function()
        RequestAnimDict(ANIM_DICT)
        RequestWeaponAsset(throwable.hash)
        while not (HasAnimDictLoaded(ANIM_DICT) and HasWeaponAssetLoaded(throwable.hash)) do Wait(10) end

        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 2.0, -2.0, -1, 48, 0, false, false, false)
        Wait(400)

        FireNetworkedProjectile(ped, throwable.hash, throwable.speed)
        TriggerServerEvent('tactical_lite:throwItem', throwable.item)

        Wait(200)
        StopAnimTask(ped, ANIM_DICT, ANIM_NAME, 1.0)
        Grenade.isThrowing = false
        RemoveAnimDict(ANIM_DICT)
    end)
end

RegisterCommand('quick_throw', ProcessQuickThrow, false)
RegisterKeyMapping('quick_throw', 'Quick Tactical Throw', 'keyboard', config.QuickThrow.Key)

local isLeanLeftPressed, isLeanRightPressed = false, false
RegisterCommand('+lean_left', function() isLeanLeftPressed = true end, false)
RegisterCommand('-lean_left', function() isLeanLeftPressed = false end, false)
RegisterCommand('+lean_right', function() isLeanRightPressed = true end, false)
RegisterCommand('-lean_right', function() isLeanRightPressed = false end, false)
RegisterKeyMapping('+lean_left', 'Tactical Lean Left', 'keyboard', 'Q')
RegisterKeyMapping('+lean_right', 'Tactical Lean Right', 'keyboard', 'E')

lib.onCache('weapon', function(weapon)
    if not weapon then
        if Lean.f > 0 then
            Lean.Update(cache.ped, false, false, false)
        end
        return
    end

    CreateThread(function()
        local setpov = false
        while cache.weapon do
            local isAiming = IsPlayerFreeAiming(cache.playerId) or IsControlPressed(0, 25)

            if isAiming then
                Lean.Update(cache.ped, true, isLeanLeftPressed, isLeanRightPressed)
                DisableControlAction(0, 0, true)

                local currentMode = GetFollowPedCamViewMode()
                if currentMode ~= 4 and currentMode ~= 0 then
                    SetFollowPedCamViewMode(0)
                end

                if IsDisabledControlJustPressed(0, 0) then
                    setpov = not setpov
                    SetFollowPedCamViewMode(setpov and 4 or 0)
                end
            else
                if Lean.f > 0 then
                    Lean.Update(cache.ped, false, false, false)
                end
                setpov = false
                EnableControlAction(0, 0, true)
            end
            Wait(0)
        end
    end)
end)