local config = require 'vip.config'

local function isPlayerAdmin(src)
    return IsPlayerAceAllowed(src, "admin")
end

local function getFivemIdentifier(src)
    local identifier = GetPlayerIdentifierByType(src, 'fivem')
    if not identifier then
        identifier = GetPlayerIdentifierByType(src, 'license2')
    end
    return identifier
end

local function getSubscriptionFromIdentifier(identifier)
    local userId = exports.qbx_core:GetUserId(identifier)
    if not userId then return nil end

    local result = MySQL.query.await([[
        SELECT subscription FROM subscription_users WHERE userId = ?;
    ]], { userId })

    if result and #result > 0 then
        return result[1].subscription
    end

    return nil
end

local function getSubscriptionFromSrc(src)
    local identifier = getFivemIdentifier(src)
    if not identifier then return nil end
    return getSubscriptionFromIdentifier(identifier)
end

local function setSubscriptionFromIdentifier(identifier, subscription)
    local userId = exports.qbx_core:GetUserId(identifier)
    if not userId then return false end

    if subscription and subscription ~= '' then
        MySQL.query.await([[
            INSERT INTO subscription_users (userId, subscription) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE subscription = VALUES(subscription);
        ]], { userId, subscription })
    else
        MySQL.query.await([[
            DELETE FROM subscription_users WHERE userId = ?;
        ]], { userId })
    end

    return true
end

local function setSubscriptionFromSrc(src, subscription)
    local identifier = getFivemIdentifier(src)
    if not identifier then return false end
    local success = setSubscriptionFromIdentifier(identifier, subscription)
    if success then
        local playerState = Player(src).state
        playerState:set('subscription', subscription, true)
    end
    return success
end

CreateThread(function()
    local success, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS subscription_users (
                userId INT NOT NULL,
                subscription VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (userId)
            );
        ]])

        lib.print.info('Subscription users table ensured.')
    end)

    if not success then
        lib.print.error('Error creating subscription users table: ' .. tostring(err))
    end
end)

lib.callback.register('vip:server:getSubscription', function(source, targetSrc)
    if not isPlayerAdmin(source) then return nil end
    return getSubscriptionFromSrc(targetSrc)
end)

lib.callback.register('vip:server:setSubscription', function(source, targetSrc, subscription)
    if not isPlayerAdmin(source) then return false end
    return setSubscriptionFromSrc(targetSrc, subscription)
end)

lib.callback.register('vip:server:checkAdmin', function(source)
    return isPlayerAdmin(source)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local subscription = getSubscriptionFromSrc(src)
    if subscription then
        local playerState = Player(src).state
        playerState:set('subscription', subscription, true)
    end
end)

exports('GetSubFromSrc', getSubscriptionFromSrc)
exports('SetSubFromSrc', setSubscriptionFromSrc)
exports('GetSubFromIdentifier', getSubscriptionFromIdentifier)
exports('SetSubFromIdentifier', setSubscriptionFromIdentifier)