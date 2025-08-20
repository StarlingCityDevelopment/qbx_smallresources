local config = {
    {
        name = 'Owner',
        value = 'Codexis',
    },
    -- {
    --     name = 'Description',
    --     value = 'Starling City est un serveur roleplay, offrant une expérience immersive et communautaire.',
    -- },
    {
        name = 'Site Web',
        value = 'https://starlingrp.fr',
    },
    {
        name = 'Âge',
        value = '18+',
    },
    {
        name = 'Gamemode Type',
        value = 'Roleplay',
    },
    {
        name = 'Développement',
        value = 'Un gameplay immersif et parfaitement optimisé, porté par des scripts personnalisés alliant fun et performance.',
    }
}

for i = 1, #config do
    SetConvarServerInfo(config[i].name, config[i].value)
end