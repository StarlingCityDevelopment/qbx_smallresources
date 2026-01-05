local config = require 'vip.config'

local isAdmin = false
local function checkAdmin()
    if isAdmin then
        return isAdmin
    end
    isAdmin = lib.callback.await('vip:server:checkAdmin', 2500)
    print(isAdmin)
    return isAdmin
end

local function openSetMenu(src, username, currentSub)
    local options = { { value = '', label = 'Aucun' } }
    for sub, label in pairs(config.subscriptions) do
        table.insert(options, { value = sub, label = label })
    end

    local input = lib.inputDialog('Définir l\'abonnement pour ' .. username, {
        { type = 'select', label = 'Abonnement', options = options, default = currentSub or '' }
    })
    if not input then return end

    local newSub = input[1] == '' and nil or input[1]
    local success = lib.callback.await('vip:server:setSubscription', 1000, src, newSub)
    if success then
        lib.notify({ type = 'success', description = 'Abonnement défini avec succès' })
    else
        lib.notify({ type = 'error', description = 'Échec de la définition de l\'abonnement' })
    end
end

exports.ox_target:addGlobalPlayer({
    {
        me = true,
        label = "Gérer les abbonnements",
        name = "sub_management",
        icon = 'fas fa-crown',
        openMenu = "sub_management_menu",
        canInteract = function()
            return checkAdmin()
        end,
    },
    {
        me = true,
        name = 'view_subscription',
        label = 'Obtenir l\'abonnement',
        icon = 'fas fa-crown',
        menuName = "sub_management_menu",
        onSelect = function(data)
            local targetPlayer = NetworkGetPlayerIndexFromPed(data.entity)
            local targetSrc = GetPlayerServerId(targetPlayer)
            local currentSub = lib.callback.await('vip:server:getSubscription', 1000, targetSrc)
            lib.notify({
                type = 'info',
                description = "L'abonnement est : " ..
                (currentSub and (config.subscriptions[currentSub] or currentSub) or 'Aucun'),
            })
        end
    },
    {
        me = true,
        name = 'set_subscription',
        label = 'Définir l\'abonnement',
        icon = 'fas fa-crown',
        menuName = "sub_management_menu",
        onSelect = function(data)
            local targetPlayer = NetworkGetPlayerIndexFromPed(data.entity)
            local targetSrc = GetPlayerServerId(targetPlayer)
            local username = GetPlayerName(targetPlayer)
            local currentSub = lib.callback.await('vip:server:getSubscription', 1000, targetSrc)
            openSetMenu(targetSrc, username, currentSub)
        end
    }
})
