local isPlacing = false
local isRepositioning = false
local previewPed = nil
local selectedModel = nil
local spawnedPeds = {}
local selectedAnimationIndex = 1
local repositioningData = nil

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        cameraCoord.x, cameraCoord.y, cameraCoord.z,
        destination.x, destination.y, destination.z,
        1, PlayerPedId(), 4
    )
    local _, hit, endCoords, _, entity = GetShapeTestResult(rayHandle)
    return hit, endCoords, entity
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function PlacePed(coords, heading)
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    local ped = CreatePed(4, GetHashKey(selectedModel), coords.x, coords.y, coords.z, heading or 0.0, true, true)

    if not DoesEntityExist(ped) then
        return
    end

    SetPedRandomComponentVariation(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    FreezeEntityPosition(ped, true)

    table.insert(spawnedPeds, {
        handle = ped,
        animation = selectedAnimationIndex
    })

    if selectedAnimationIndex ~= 'none' then
        exports.scully_emotemenu:playEmoteByCommand(selectedAnimationIndex, 0, ped)
    end

    lib.hideTextUI()

    isPlacing = false
    previewPed = nil

    SetModelAsNoLongerNeeded(GetHashKey(selectedModel))
end

function CancelPlacement()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    lib.hideTextUI()

    isPlacing = false
    previewPed = nil

    if selectedModel then
        SetModelAsNoLongerNeeded(GetHashKey(selectedModel))
    end
end

function BeginPedPlacement()
    if not selectedModel or not lib.requestModel(selectedModel) then
        return
    end

    isPlacing = true
    local pedHeading = 0.0

    local coords = GetEntityCoords(PlayerPedId())
    previewPed = CreatePed(4, GetHashKey(selectedModel), coords.x, coords.y, coords.z - 1.0, pedHeading, false, false)

    if not DoesEntityExist(previewPed) then
        isPlacing = false
        return
    end

    SetEntityAlpha(previewPed, 200, false)
    FreezeEntityPosition(previewPed, true)
    SetEntityCollision(previewPed, false, false)

    if selectedAnimationIndex ~= 'none' then
        exports.scully_emotemenu:playEmoteByCommand(selectedAnimationIndex, 0, previewPed)
    end

    lib.showTextUI('[ENTRÉE] Placer le PNJ | [MOLETTE] Rotation | [ÉCHAP] Annuler', {
        position = "top-center",
        icon = 'user',
        style = {
            borderRadius = 0,
            backgroundColor = '#141517',
            color = 'white'
        }
    })

    lib.addKeybind({
        name = 'place_ped',
        description = 'Placer le PNJ',
        defaultKey = 'RETURN',
        onPressed = function()
            if isPlacing and previewPed and DoesEntityExist(previewPed) then
                local hit, coords, entity = RayCastGamePlayCamera(10.0)
                if hit then
                    PlacePed(coords, pedHeading)
                end
            end
        end
    })

    lib.addKeybind({
        name = 'cancel_placement',
        description = 'Annuler le placement',
        defaultKey = 'ESCAPE',
        onPressed = function()
            if isPlacing then
                CancelPlacement()
            end
        end
    })

    CreateThread(function()
        while isPlacing do
            Wait(0)

            local hit, coords, entity = RayCastGamePlayCamera(10.0)

            if hit then
                SetEntityCoords(previewPed, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(previewPed, pedHeading)


                if IsControlJustPressed(0, 14) then -- Mousewheel down
                    pedHeading = pedHeading + 15.0
                    if pedHeading >= 360.0 then pedHeading = 0.0 end
                    SetEntityHeading(previewPed, pedHeading)
                elseif IsControlJustPressed(0, 15) then -- Mousewheel up
                    pedHeading = pedHeading - 15.0
                    if pedHeading < 0.0 then pedHeading = 345.0 end
                    SetEntityHeading(previewPed, pedHeading)
                end
            end

            if not isPlacing then
                break
            end
        end
    end)
end

function BeginRepositioningPed(pedData, pedIndex)
    if isPlacing or isRepositioning then
        return
    end

    local ped = pedData.handle

    if not DoesEntityExist(ped) then
        return
    end

    isRepositioning = true
    local pedHeading = GetEntityHeading(ped)
    local pedModel = GetEntityModel(ped)
    local pedAnimation = pedData.animation or 1

    local pedCoords = GetEntityCoords(ped)
    previewPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, pedHeading, false, false)
    SetEntityAlpha(previewPed, 200, false)
    FreezeEntityPosition(previewPed, true)
    SetEntityCollision(previewPed, false, false)

    if pedAnimation ~= 'none' then
        exports.scully_emotemenu:playEmoteByCommand(pedAnimation, 0, previewPed)
    end

    SetEntityAlpha(ped, 0, false)

    lib.showTextUI('[ENTRÉE] Placer le PNJ | [MOLETTE] Rotation | [ÉCHAP] Annuler', {
        position = "top-center",
        icon = 'user',
        style = {
            borderRadius = 0,
            backgroundColor = '#141517',
            color = 'white'
        }
    })

    repositioningData = {
        pedIndex = pedIndex,
        animation = pedAnimation
    }



    lib.addKeybind({
        name = 'confirm_reposition',
        description = 'Confirmer le repositionnement',
        defaultKey = 'RETURN',
        onPressed = function()
            if isRepositioning and previewPed and DoesEntityExist(previewPed) then
                local hit, coords, entity = RayCastGamePlayCamera(10.0)
                if hit then
                    FinishRepositioningPed(coords, pedHeading)
                end
            end
        end
    })

    lib.addKeybind({
        name = 'cancel_reposition',
        description = 'Annuler le repositionnement',
        defaultKey = 'ESCAPE',
        onPressed = function()
            if isRepositioning then
                CancelRepositioningPed()
            end
        end
    })

    CreateThread(function()
        while isRepositioning do
            Wait(0)

            local hit, coords, entity = RayCastGamePlayCamera(10.0)

            if hit then
                SetEntityCoords(previewPed, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(previewPed, pedHeading)


                if IsControlJustPressed(0, 14) then -- Mousewheel down
                    pedHeading = pedHeading + 15.0
                    if pedHeading >= 360.0 then pedHeading = 0.0 end
                    SetEntityHeading(previewPed, pedHeading)
                elseif IsControlJustPressed(0, 15) then -- Mousewheel up
                    pedHeading = pedHeading - 15.0
                    if pedHeading < 0.0 then pedHeading = 345.0 end
                    SetEntityHeading(previewPed, pedHeading)
                end
            end

            if not isRepositioning then
                break
            end
        end
    end)
end

function FinishRepositioningPed(coords, heading)
    if not repositioningData then return end

    local pedIndex = repositioningData.pedIndex
    local animIndex = repositioningData.animation

    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    local ped = spawnedPeds[pedIndex].handle

    if DoesEntityExist(ped) then
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, heading)
        SetEntityAlpha(ped, 255, false)
        FreezeEntityPosition(ped, true)

        ClearPedTasksImmediately(ped)
        if animIndex ~= 'none' then
            exports.scully_emotemenu:playEmoteByCommand(animIndex, 0, ped)
        end
    end

    lib.hideTextUI()

    isRepositioning = false
    previewPed = nil
    repositioningData = nil
end

function CancelRepositioningPed()
    if not repositioningData then return end

    local pedIndex = repositioningData.pedIndex

    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    local ped = spawnedPeds[pedIndex].handle

    if DoesEntityExist(ped) then
        SetEntityAlpha(ped, 255, false)
    end

    lib.hideTextUI()

    isRepositioning = false
    previewPed = nil
    repositioningData = nil
end

function ChangeAnimation(pedIndex)
    local pedData = spawnedPeds[pedIndex]
    if not pedData or not DoesEntityExist(pedData.handle) then
        return
    end

    local input = lib.inputDialog('Changer l\'animation', {
        {
            type = 'input',
            label = 'Sélectionner une animation (ex: argue)',
            default = pedData.animation
        }
    })

    if input and input[1] then
        local newAnimIndex = input[1]
        pedData.animation = newAnimIndex

        ClearPedTasksImmediately(pedData.handle)
        if pedData.animation ~= 'none' then
            exports.scully_emotemenu:playEmoteByCommand(newAnimIndex, 0, pedData.handle)
        end
        FreezeEntityPosition(pedData.handle, true)
    end
end

function OpenSpawnDialog()
    local input = lib.inputDialog('Générateur de PNJ', {
        { type = 'input', label = 'Sélectionner un modèle de PNJ',         required = true },
        { type = 'input', label = 'Sélectionner une animation (ex: argue)' }
    })

    if input and input[1] then
        selectedModel = input[1]
        selectedAnimationIndex = input[2] or 'none'
        BeginPedPlacement()
    end
end

function OpenPedMenu()
    local options = {}

    table.insert(options, {
        title = 'Créer un nouveau PNJ',
        description = 'Créer un nouveau PNJ dans le monde',
        icon = 'user-plus',
        onSelect = function()
            OpenSpawnDialog()
        end
    })

    local pedCount = 0
    for i, pedData in ipairs(spawnedPeds) do
        local ped = pedData.handle
        if DoesEntityExist(ped) then
            pedCount = pedCount + 1
            local pedCoords = GetEntityCoords(ped)
            local pedModel = GetEntityModel(ped)

            table.insert(options, {
                title = pedModel .. ' #' .. i,
                description = 'Position: ' .. math.floor(pedCoords.x) .. ', ' .. math.floor(pedCoords.y),
                icon = 'user',
                menu = 'ped_' .. i,
                metadata = {
                    { label = 'Modèle',    value = pedModel },
                    { label = 'Animation', value = pedData.animation },
                    { label = 'Position',  value = math.floor(pedCoords.x) .. ', ' .. math.floor(pedCoords.y) .. ', ' .. math.floor(pedCoords.z) }
                }
            })

            lib.registerContext({
                id = 'ped_' .. i,
                title = 'Gérer: ' .. pedModel .. ' #' .. i,
                menu = 'ped_menu',
                options = {
                    {
                        title = 'Repositionner',
                        description = 'Déplacer ce PNJ vers un nouvel emplacement',
                        icon = 'arrows-up-down-left-right',
                        onSelect = function()
                            BeginRepositioningPed(pedData, i)
                        end
                    },
                    {
                        title = 'Changer l\'animation',
                        description = 'Appliquer une animation différente à ce PNJ',
                        icon = 'film',
                        onSelect = function()
                            ChangeAnimation(i)
                        end
                    },
                    {
                        title = 'Se téléporter vers',
                        description = 'Vous téléporter vers ce PNJ',
                        icon = 'location-arrow',
                        onSelect = function()
                            local pCoords = GetEntityCoords(ped)
                            SetEntityCoords(PlayerPedId(), pCoords.x, pCoords.y, pCoords.z + 1.0, false, false, false,
                                false)
                        end
                    },
                    {
                        title = 'Supprimer',
                        description = 'Retirer ce PNJ du monde',
                        icon = 'trash',
                        onSelect = function()
                            DeleteEntity(ped)
                            table.remove(spawnedPeds, i)
                        end
                    }
                }
            })
        end
    end

    if pedCount > 0 then
        table.insert(options, {
            title = 'Supprimer tous les PNJ',
            description = 'Retirer tous les PNJ placés',
            icon = 'trash-can',
            onSelect = function()
                local count = 0
                for _, pedData in ipairs(spawnedPeds) do
                    if DoesEntityExist(pedData.handle) then
                        DeleteEntity(pedData.handle)
                        count = count + 1
                    end
                end

                spawnedPeds = {}
            end
        })
    end

    lib.registerContext({
        id = 'ped_menu',
        title = 'Générateur et Gestionnaire de PNJ',
        options = options
    })

    lib.showContext('ped_menu')
end

RegisterCommand('pedmenu', function()
    OpenPedMenu()
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    for _, pedData in ipairs(spawnedPeds) do
        if pedData.handle and DoesEntityExist(pedData.handle) then
            DeleteEntity(pedData.handle)
        end
    end

    if isPlacing or isRepositioning then
        lib.hideTextUI()
    end
end)