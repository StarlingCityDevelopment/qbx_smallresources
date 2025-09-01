if not GetConvar('environment', 'production') == 'development' then return end

RegisterServerEvent('betatest:setjob', function(job, grade)
    local src = source
    exports.qbx_core:SetJob(src, job, grade)
    lib.notify(src, {
        title = 'Métier défini',
        description = 'Vous êtes maintenant ' .. job .. ' grade ' .. grade,
        type = 'success'
    })
end)

RegisterServerEvent('betatest:setgang', function(gang, grade)
    local src = source
    exports.qbx_core:SetGang(src, gang, grade)
    lib.notify(src, {
        title = 'Gang défini',
        description = 'Vous êtes maintenant dans le gang ' .. gang .. ' grade ' .. grade,
        type = 'success'
    })
end)

RegisterServerEvent('betatest:giveitem', function(item, count)
    local src = source
    if not src or not item or not count then return end

    count = tonumber(count)
    if not count or count < 1 or count > 999 then
        lib.notify(src, {
            title = 'Erreur',
            description = 'Quantité invalide (1-999)',
            type = 'error'
        })
        return
    end

    exports.ox_inventory:AddItem(src, item, count)
    lib.notify(src, {
        title = 'Objet reçu',
        description = 'Vous avez reçu ' .. count .. 'x ' .. item,
        type = 'success'
    })
end)

RegisterServerEvent('betatest:spawnvehicle', function(vehicleModel)
    local src = source
    if not src or not vehicleModel then return end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local spawnCoords = vector3(coords.x + 2.0, coords.y, coords.z + 0.5)

    qbx.spawnVehicle({
        model = `asbo`,
        spawnSource = vec4(spawnCoords.x, spawnCoords.y, spawnCoords.z, heading),
        warp = ped,
    })
end)

RegisterServerEvent('betatest:revive', function()
    local src = source
    if not src then return end
    exports.wasabi_ambulance:RevivePlayer(src)
end)

RegisterServerEvent('betatest:teleport', function(coords)
    local src = source
    if not src or not coords then return end

    local ped = GetPlayerPed(src)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)

    lib.notify(src, {
        title = 'Téléportation',
        description = 'Vous avez été téléporté',
        type = 'success'
    })
end)