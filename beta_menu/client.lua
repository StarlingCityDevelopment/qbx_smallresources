if not GetConvar('environment', 'production') == 'development' then return end

local Config = {
    validation = {
        quantity = {
            min = 1,
            max = 999
        }
    },
    vehicles = {
        panto = 'panto'
    },
    teleports = {
        {
            name = 'Spawn',
            coords = vec4(-1103.21, -2850.74, 14.89, 332.57)
        },
        {
            name = 'Police',
            coords = vec4(-580.9, -404.89, 35.18, 178.6)
        },
        {
            name = 'Hôpital',
            coords = vec4(337.86, -1393.94, 32.51, 229.05)
        }
    },
    texts = {
        titles = {
            mainMenu = 'Menu des testeurs bêta',
            jobs = 'Sélectionner un métier',
            gangs = 'Sélectionner un gang',
            weapons = 'Sélectionner une arme',
            items = 'Sélectionner un objet',
            vehicles = 'Véhicules',
            playerActions = 'Actions joueur',
            teleports = 'Téléportation'
        },
        buttons = {
            setJob = 'Définir un métier',
            setGang = 'Définir un gang',
            getWeapon = 'Obtenir une arme',
            getItem = 'Obtenir un objet',
            spawnVehicle = 'Spawn véhicule',
            resetPlayer = 'Reset joueur',
            teleport = 'Téléportation',
            search = 'Rechercher',
            showAll = 'Afficher tout'
        },
        placeholders = {
            searchJob = 'Tapez le nom du métier...',
            searchGang = 'Tapez le nom du gang...',
            searchWeapon = 'Tapez le nom de l\'arme...',
            searchItem = 'Tapez le nom de l\'objet...',
            quantity = 'Quantité'
        },
        errors = {
            invalidQuantity = 'Quantité invalide (min: %d, max: %d)',
            noInput = 'Aucune valeur entrée'
        }
    }
}

local function validateQuantity(value)
    if not value or value < Config.validation.quantity.min or value > Config.validation.quantity.max then
        return false, string.format(Config.texts.errors.invalidQuantity,
            Config.validation.quantity.min, Config.validation.quantity.max)
    end
    return true, nil
end

local function showValidatedInput(title, placeholder, cb)
    local input = lib.inputDialog(title, {
        {
            type = 'number',
            label = placeholder,
            required = true,
            min = Config.validation.quantity.min,
            max = Config.validation.quantity.max
        },
    })
    if input and input[1] then
        local isValid, errorMsg = validateQuantity(input[1])
        if isValid then
            cb(input[1])
        else
            lib.notify(PlayerId(), {
                title = 'Erreur',
                description = errorMsg,
                type = 'error'
            })
        end
    end
end

local function showInput(title, placeholder, cb)
    showValidatedInput(title, placeholder, cb)
end

local function createFilteredMenu(config)
    local options = {}
    for name, item in pairs(config.dataSource) do
        local shouldInclude = true
        if config.searchTerm then
            local labelMatch = item.label and
            string.find(string.lower(item.label), string.lower(config.searchTerm)) ~= nil
            local nameMatch = string.find(string.lower(name), string.lower(config.searchTerm)) ~= nil
            shouldInclude = labelMatch or nameMatch
        end

        if config.filter and shouldInclude then
            shouldInclude = config.filter(name, item)
        end

        if shouldInclude then
            table.insert(options, {
                title = config.getTitle(name, item),
                onSelect = function()
                    config.onSelect(name, item)
                end
            })
        end
    end

    table.sort(options, function(a, b) return a.title < b.title end)

    local contextTitle = config.searchTerm and
        (config.category .. ' - Recherche: ' .. config.searchTerm) or
        ('Tous les ' .. string.lower(config.category))

    lib.registerContext({
        id = config.contextId,
        title = contextTitle,
        options = options
    })
    lib.showContext(config.contextId)
end

local function createSearchMenu(config)
    local input = lib.inputDialog('Rechercher ' .. string.lower(config.category), {
        { type = 'input', label = 'Nom', required = true, placeholder = config.placeholder },
    })
    if input and input[1] and string.len(input[1]) > 0 then
        local searchConfig = {}
        for k, v in pairs(config) do
            searchConfig[k] = v
        end
        searchConfig.searchTerm = input[1]
        searchConfig.contextId = config.contextId .. '_filtered'
        createFilteredMenu(searchConfig)
    end
end

local function createCategoryMenu(config)
    lib.registerContext({
        id = config.contextId,
        title = config.title,
        options = {
            {
                title = Config.texts.buttons.search .. ' ' .. string.lower(config.category),
                onSelect = function() createSearchMenu(config) end
            },
            {
                title = Config.texts.buttons.showAll .. ' ' .. string.lower(config.category),
                onSelect = function()
                    local allConfig = {}
                    for k, v in pairs(config) do
                        allConfig[k] = v
                    end
                    allConfig.contextId = config.contextId .. '_filtered'
                    createFilteredMenu(allConfig)
                end
            }
        }
    })
    lib.showContext(config.contextId)
end

local function showGradesMenu(type, name, data)
    local gradeOptions = {}
    for level, grade in pairs(data.grades) do
        table.insert(gradeOptions, {
            title = grade.name .. ' (Niveau ' .. level .. ')',
            onSelect = function()
                TriggerServerEvent('betatest:set' .. type, name, level)
            end
        })
    end
    lib.registerContext({
        id = 'beta_' .. type .. '_grades_' .. name,
        title = 'Sélectionner le grade pour ' .. data.label,
        options = gradeOptions
    })
    lib.showContext('beta_' .. type .. '_grades_' .. name)
end

local function showJobsMenu()
    createCategoryMenu({
        contextId = 'beta_jobs',
        title = Config.texts.titles.jobs,
        category = 'métiers',
        dataSource = QBX.Shared.Jobs,
        placeholder = Config.texts.placeholders.searchJob,
        getTitle = function(name, job) return job.label end,
        onSelect = function(name, job) showGradesMenu('job', name, job) end
    })
end

local function showGangsMenu()
    createCategoryMenu({
        contextId = 'beta_gangs',
        title = Config.texts.titles.gangs,
        category = 'gangs',
        dataSource = QBX.Shared.Gangs,
        placeholder = Config.texts.placeholders.searchGang,
        getTitle = function(name, gang) return gang.label end,
        onSelect = function(name, gang) showGradesMenu('gang', name, gang) end
    })
end

local function showWeaponsMenu()
    createCategoryMenu({
        contextId = 'beta_weapons',
        title = Config.texts.titles.weapons,
        category = 'armes',
        dataSource = exports.ox_inventory:Items(),
        placeholder = Config.texts.placeholders.searchWeapon,
        filter = function(name, item) return name:match('^WEAPON_') end,
        getTitle = function(name, item) return item.label end,
        onSelect = function(name, item) TriggerServerEvent('betatest:giveitem', name, 1) end
    })
end

local function showItemsMenu()
    createCategoryMenu({
        contextId = 'beta_items',
        title = Config.texts.titles.items,
        category = 'objets',
        dataSource = exports.ox_inventory:Items(),
        placeholder = Config.texts.placeholders.searchItem,
        filter = function(name, item) return not name:match('^WEAPON_') end,
        getTitle = function(name, item) return item.label end,
        onSelect = function(name, item)
            showInput('Entrez la quantité pour ' .. item.label, Config.texts.placeholders.quantity, function(count)
                TriggerServerEvent('betatest:giveitem', name, count)
            end)
        end
    })
end

local function showVehiclesMenu()
    lib.registerContext({
        id = 'beta_vehicles',
        title = Config.texts.titles.vehicles,
        options = {
            {
                title = 'Spawn Panto',
                onSelect = function()
                    TriggerServerEvent('betatest:spawnvehicle', Config.vehicles.panto)
                end
            }
        }
    })
    lib.showContext('beta_vehicles')
end

local function showPlayerActionsMenu()
    lib.registerContext({
        id = 'beta_player_actions',
        title = Config.texts.titles.playerActions,
        options = {
            {
                title = 'Revive joueur',
                onSelect = function()
                    TriggerServerEvent('betatest:revive')
                end
            }
        }
    })
    lib.showContext('beta_player_actions')
end

local function showTeleportsMenu()
    local teleportOptions = {}
    for _, location in ipairs(Config.teleports) do
        table.insert(teleportOptions, {
            title = location.name,
            onSelect = function()
                TriggerServerEvent('betatest:teleport', location.coords)
            end
        })
    end

    lib.registerContext({
        id = 'beta_teleports',
        title = Config.texts.titles.teleports,
        options = teleportOptions
    })
    lib.showContext('beta_teleports')
end

RegisterCommand('betamenu', function()
    lib.registerContext({
        id = 'beta_menu',
        title = Config.texts.titles.mainMenu,
        options = {
            { title = Config.texts.buttons.setJob,       onSelect = showJobsMenu },
            { title = Config.texts.buttons.setGang,      onSelect = showGangsMenu },
            { title = Config.texts.buttons.getWeapon,    onSelect = showWeaponsMenu },
            { title = Config.texts.buttons.getItem,      onSelect = showItemsMenu },
            { title = Config.texts.buttons.spawnVehicle, onSelect = showVehiclesMenu },
            { title = Config.texts.buttons.resetPlayer,  onSelect = showPlayerActionsMenu },
            { title = Config.texts.buttons.teleport,     onSelect = showTeleportsMenu },
        }
    })
    lib.showContext('beta_menu')
end, false)