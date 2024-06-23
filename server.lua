local pagersList = {}

--------------------------------------------------------------------------
-- Get pager data after a player joined and finished loaded
--------------------------------------------------------------------------
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function() 
    local citizenId = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    GetPagerData(citizenId, source)
end)

--------------------------------------------------------------------------
-- Loads pager data for every player ingame on resource start
-- (usefull when u restart this script live)
--------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    local players = exports.qbx_core:GetQBPlayers()
    for id, obj in pairs(players) do
        local citizenid = exports.qbx_core:GetPlayer(id).PlayerData.citizenid
        GetPagerData(citizenid, id)
    end
end)

--------------------------------------------------------------------------
-- Returns max id from table and returns MAX(id) + 1 as a new id
--------------------------------------------------------------------------
function GetNewID(tableName)
    local row = MySQL.single.await('SELECT MAX(id) FROM ' .. tableName)
    local newid = row['MAX(id)']
    if newid ~= nil then
        newid = tonumber(newid) + 1
    else
        newid = 0
    end
    return newid
end

--------------------------------------------------------------------------
-- Returns players number if given
-- else, creates a new number
--------------------------------------------------------------------------
function GetNumber(citizenid)
    local usersRow = MySQL.single.await('SELECT number FROM pager_users WHERE citizenid = ?', {citizenid})
    local number = ''
    if usersRow == nil then
        local newNumber = CreateRandomNumber()
        MySQL.insert.await('INSERT INTO pager_users (citizenid, number) VALUES (?, ?)', {citizenid, newNumber})
        number = newNumber
    else
        number = usersRow['number']
    end
    return number
end

--------------------------------------------------------------------------
-- Returns all messages the player has
--------------------------------------------------------------------------
function GetMessages(citizenid)
    local response = MySQL.query.await('SELECT pager_messages.message as text, pager_users.number FROM pager_messages, pager_messages_users, pager_users WHERE pager_messages_users.user = ? AND pager_messages.id = pager_messages_users.message AND pager_users.citizenid = pager_messages.user', {citizenid})
    return response
end

--------------------------------------------------------------------------
-- Returns all contacts the player has
--------------------------------------------------------------------------
function GetContacts(citizenid)
    local response = MySQL.query.await('SELECT pager_contacts.name, pager_users.number, pager_contacts.user FROM pager_contacts, pager_contacts_users, pager_users WHERE pager_contacts_users.user = ? AND pager_contacts.id = pager_contacts_users.contact AND pager_users.citizenid = pager_contacts.user', {citizenid})
    return response
end

--------------------------------------------------------------------------
-- Saves pager data and players serverid inside pagerList variable
--------------------------------------------------------------------------
function GetPagerData(citizenid, serverid)
    local number = GetNumber(citizenid)
    local contacts = GetContacts(citizenid)
    local messages = GetMessages(citizenid)
    pagersList[citizenid] = {
        number = number,
        contacts = contacts,
        messages = messages,
        serverid = serverid
    }
end

--------------------------------------------------------------------------
-- Creates a random number for new players
--------------------------------------------------------------------------
function CreateRandomNumber()
    local number = ""
    local maxChars = 8
    local count = 1
    
    while count <= maxChars do
        number = number ..math.random(9)
        count = count + 1
    end

    return number
end

--------------------------------------------------------------------------
-- Callback to get pager data from server
--------------------------------------------------------------------------
lib.callback.register('96rp-pager:server:GetPagerData', function(source)
    while exports.qbx_core:GetPlayer(source) == nil do
        Wait(100)
    end
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    while pagersList[citizenid] == nil do
        Wait(100)
    end
    return pagersList[citizenid]
end)

--------------------------------------------------------------------------
-- Command for texting other players
--------------------------------------------------------------------------
RegisterCommand("pager", function(source, args, rawCommand)
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    local pagerUser = pagersList[citizenid]
    local contact = args[1]
    if tonumber(contact) == nil then
        for _, contactData in pairs(pagerUser.contacts) do
            if string.upper(contactData.name) == string.upper(contact) then
                contact = contactData.number
            end
        end
    end
    local message = args[2]
    for i = 3, #args
    do
        message = message .. " " .. args[i]
    end
    local userFound = false
    for currentCitizenid, values in pairs(pagersList) do
        if values.number == tonumber(contact) then
            local newID = GetNewID('pager_messages')
            MySQL.insert.await('INSERT INTO pager_messages (id, message, user) VALUES (?, ?, ?)', {newID , message, citizenid})
            MySQL.insert.await('INSERT INTO pager_messages_users (user, message) VALUES (?, ?)', {currentCitizenid, newID})
            TriggerClientEvent('96rp-pager:pager:received', values.serverid, pagerUser.number, 'Private message', message)
            userFound = true
        end
    end
    if not userFound then
        local pagerTune = Config.Pager[contact];

        if(pagerTune == nil) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = "The paged channel does not exist."
            })
            return false;
        end

        local Player = exports.qbx_core:GetPlayer(source)
        local authorized=false;

        if pagerTune.jobPermissions ~= nil then
            for k,v in ipairs(pagerTune.jobPermissions) do
                if(Player.PlayerData.jobs[v]) then
                    authorized=true;
                    break
                end
            end

            if authorized == false then
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    description = "You are not authenticated to broadcast on the paged channel."
                })
                return false;
            end

        end

        if pagerTune.discordPermissions ~= nil then
            authorized=exports["pv-discord-uac"]:doesUserHaveAnyRole(source,pagerTune.discordPermissions);

            if authorized == false then
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    description = "You are not authenticated to broadcast on the paged channel."
                })
                return false;
            end
        end
        
        if pagerTune.jobPermissions == nil and pagerTune.discordPermissions == nil then authorized=true end

        if authorized then
            local players = exports.qbx_core:GetQBPlayers()
            for _, v in pairs(players) do
                if(pagerTune.broadcastToJobs[v.PlayerData.job.name]) then
                    local number = pagersList[v.PlayerData.citizenid].number
                    if(pagerTune.broadcastToRoles ~= nil) then
                        if(exports["pv-discord-uac"]:doesUserHaveAnyRole(v.PlayerData.source,pagerTune.broadcastToRoles)) then
                            TriggerClientEvent("96rp-pager:pager:received",  v.PlayerData.source, number, contact, message);
                        end
                    else
                        TriggerClientEvent("96rp-pager:pager:received",  v.PlayerData.source, number, contact, message);
                    end

                end
            end
        end

        for k,v in ipairs(pagerTune.webhooks) do
            SendToDiscord(k,pagerTune.title, message, v);
        end

        SendToDiscord(Config.LogWebhook,pagerTune.title, message, "New pager!",source,true);
    end
end, false)

--------------------------------------------------------------------------
-- Saves a new contact
--------------------------------------------------------------------------
RegisterNetEvent('96rp-pager:server:SaveContact', function(name, number)
    local src = source
    local newID = GetNewID('pager_contacts')
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid

    local row = MySQL.single.await('SELECT citizenid FROM pager_users WHERE number = ?', {number})
    MySQL.insert.await('INSERT INTO pager_contacts (id, name, user) VALUES (?, ?, ?)', {newID , string.upper(name), row['citizenid']})
    MySQL.insert.await('INSERT INTO pager_contacts_users (user, contact) VALUES (?, ?)', {citizenid, newID})
end)

--------------------------------------------------------------------------
-- Removes given contact
--------------------------------------------------------------------------
RegisterNetEvent('96rp-pager:server:RemoveContact', function(number)
    local src = source
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid

    local contactid = MySQL.single.await('SELECT pager_contacts.id FROM pager_contacts, pager_contacts_users WHERE pager_contacts.id = pager_contacts_users.contact AND pager_contacts_users.user = ? AND  pager_contacts.user = (SELECT citizenid FROM pager_users WHERE number = ?)', {citizenid, number})['id']

    MySQL.single.await('DELETE FROM pager_contacts_users WHERE contact = ?', {contactid})
    MySQL.single.await('DELETE FROM pager_contacts WHERE id = ?', {contactid})
end)

function SendToDiscord(url,title,text, content,src, admin)
    local embed = {
        {
            ["color"] = 10038562,
            ["title"] = "Pager - " .. title,
            ["description"] = text,
        }
    }

    if(admin ~= nil and admin == true) then

        local discord="";

        for k, v in pairs(GetPlayerIdentifiers(src)) do
            if string.sub(v, 1, string.len("discord:")) == "discord:" then
                discord = v
            end
        end

        discord = string.gsub(discord, "discord:", "");

        embed[1].fields = {
                {
                    ["name"]="Sent by",
                    ["value"]="<@" .. discord .. ">"
                }
        };
    end

    PerformHttpRequest(url, function(err, text, headers) end, 'POST', json.encode({username = "Pager", embeds = embed, content = content,}), { ['Content-Type'] = 'application/json' })
end