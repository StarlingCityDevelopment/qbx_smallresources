local config = require 'cdx_fixwater.config'

local zones = {}

local function getVolumeBounds(center, size)
    local half = size / 2
    return {
        min = vector3(center.x - half.x, center.y - half.y, center.z - half.z),
        max = vector3(center.x + half.x, center.y + half.y, center.z + half.z)
    }
end

local function draw3DBox(bounds)
    local min, max = bounds.min, bounds.max

    local color = { r = 255, g = 0, b = 0, a = 255 }

    DrawLine(min.x, min.y, min.z, max.x, min.y, min.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, min.y, min.z, max.x, max.y, min.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, max.y, min.z, min.x, max.y, min.z, color.r, color.g, color.b, color.a)
    DrawLine(min.x, max.y, min.z, min.x, min.y, min.z, color.r, color.g, color.b, color.a)

    DrawLine(min.x, min.y, max.z, max.x, min.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, min.y, max.z, max.x, max.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, max.y, max.z, min.x, max.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(min.x, max.y, max.z, min.x, min.y, max.z, color.r, color.g, color.b, color.a)

    DrawLine(min.x, min.y, min.z, min.x, min.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, min.y, min.z, max.x, min.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(max.x, max.y, min.z, max.x, max.y, max.z, color.r, color.g, color.b, color.a)
    DrawLine(min.x, max.y, min.z, min.x, max.y, max.z, color.r, color.g, color.b, color.a)
end

Citizen.CreateThread(function()
    for _, v in ipairs(config.zones) do
        v.bounds = getVolumeBounds(v.center, v.size)
        zones[#zones+1] = CreateDryVolume(
            v.bounds.min.x, v.bounds.min.y, v.bounds.min.z,
            v.bounds.max.x, v.bounds.max.y, v.bounds.max.z
        )
    end

    while config.debug do
        for _, v in ipairs(config.zones) do
            draw3DBox(v.bounds)
        end
        Citizen.Wait(0)
    end
end)

AddEventHandler('cdx_fixwater:enter', function()
    for _, zone in pairs(zones) do
        RemoveDryVolume(zone)
    end
end)