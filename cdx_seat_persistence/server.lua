local function findVehicleByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if qbx.getVehiclePlate(veh) == plate then
            return veh
        end
    end
    return nil
end

RegisterNetEvent('cdx_seat_persistence:server:update', function (seat)
    local src = source
    local ped = GetPlayerPed(src)

    if not seat then
        exports.qbx_core:SetMetadata(src, 'cdx_seat_persistence', false)
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return end

    local plate = qbx.getVehiclePlate(vehicle)
    if not plate then return end

    exports.qbx_core:SetMetadata(src, 'cdx_seat_persistence', {
        seat = seat,
        plate = plate,
    })
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function ()
    local src = source
    local ped = GetPlayerPed(src)

    Wait(5000)

    local metadata = exports.qbx_core:GetMetadata(src, 'cdx_seat_persistence')
    if not metadata then return end

    local seat = metadata.seat
    local plate = metadata.plate
    local vehicle = findVehicleByPlate(plate)

    if not vehicle or not DoesEntityExist(vehicle) then
        exports.qbx_core:SetMetadata(src, 'cdx_seat_persistence', false)
        lib.print.error('[CDX-SEAT-PERSISTENCE] Vehicle not found')
        return
    end

    if GetPedInVehicleSeat(vehicle, seat) == 0 then
        SetPedIntoVehicle(ped, vehicle, seat)
        return
    end

    for i = -1, 6 do
        if GetPedInVehicleSeat(vehicle, i) == 0 then
            SetPedIntoVehicle(ped, vehicle, i)
            return
        end
    end
end)