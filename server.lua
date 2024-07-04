local pagersList = {}


--------------------------------------------------------------------------
-- Database updates
--------------------------------------------------------------------------
CreateThread(function()
    local waitTime = 3600000
    while true do
        print("--------------------------")
        print("update database check")
        UpdateDatabase()
        print("--------------------------")
        Wait(waitTime)
    end
end)

--------------------------------------------------------------------------
-- Get pager data after a player joined and finished loaded
--------------------------------------------------------------------------
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function() 
    local src = source
    local citizenId = exports.qbx_core:GetPlayer(src).PlayerData.citizenid
    GetPagerData(citizenId, src)
    Player(src).state.pagerObj = nil
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
        Player(id).state.pagerObj = nil
    end
end)

--------------------------------------------------------------------------
-- Admin command to save pager data
--------------------------------------------------------------------------
RegisterCommand("savePagers", function(source, args, rawCommand)
	UpdateDatabase()
end, true) 

--------------------------------------------------------------------------
-- Save data on restart schedule
--------------------------------------------------------------------------
AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
	UpdateDatabase()
end)

--------------------------------------------------------------------------
-- Save data before shutting down
--------------------------------------------------------------------------
AddEventHandler('txAdmin:events:serverShuttingDown', function()
	UpdateDatabase()
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
    local response = MySQL.query.await('SELECT pager_contacts.id, pager_contacts.name, pager_users.number, pager_contacts.user as contactCitizenID FROM pager_contacts, pager_contacts_users, pager_users WHERE pager_contacts_users.user = ? AND pager_contacts.id = pager_contacts_users.contact AND pager_users.citizenid = pager_contacts.user', {citizenid})
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
-- Checks if pager data is changed locally and updates the db
--------------------------------------------------------------------------
function UpdateDatabase()
	for currentCitizenID, currentPagerData in pairs(pagersList) do
        local removedData = {}

        for i = 1, #currentPagerData.contacts do
            local currentContact = currentPagerData.contacts[i]
            local contactCitizenID = MySQL.single.await('SELECT citizenid FROM pager_users WHERE number = ?', {currentContact.number})['citizenid']

            -- new contact
            if currentContact.isNew ~= nil then
                local newID = GetNewID('pager_contacts')
                MySQL.insert.await('INSERT INTO pager_contacts (id, name, user) VALUES (?, ?, ?)', {newID, currentContact.name, contactCitizenID})
                MySQL.insert.await('INSERT INTO pager_contacts_users (user, contact) VALUES (?, ?)', {currentCitizenID, newID})
                currentContact.isNew = nil
                currentContact.id = newID
                currentContact.contactCitizenID = contactCitizenID
                print(string.format("added #%s %s as %s to %s contacts", newID, contactCitizenID, currentContact.name, currentCitizenID))
            end

            -- removed contact
            if currentContact.removed ~= nil then
                MySQL.single.await('DELETE FROM pager_contacts_users WHERE contact = ?', {currentContact.id})
                MySQL.single.await('DELETE FROM pager_contacts WHERE id = ?', {currentContact.id})
                table.insert(removedData, i)
                print(string.format("removed #%s %s contact from %s", currentContact.id, contactCitizenID, currentCitizenID))
            end
            
            -- updated contact
            if currentContact.isUpdated ~= nil then
                MySQL.update.await('UPDATE pager_contacts SET name = ? WHERE id = ?', { currentContact.name, currentContact.id})
                currentContact.isUpdated = nil
                print(string.format("updated #%s %s contact from %s", currentContact.id, contactCitizenID, currentCitizenID))
            end
        end

        --remove contacts localy
        for i = 1, #removedData do
            table.remove(currentPagerData.contacts, removedData[i])
        end

        for otherCitizenID, otherPagerData in pairs(pagersList) do

            for i = 1, #currentPagerData.messages do
                local currentMessage = currentPagerData.messages[i]

                -- check for new message and search for right pager data from contact
                if currentMessage.isNew and otherPagerData.number == currentMessage.number then
                    local newID = GetNewID('pager_messages')
                    MySQL.insert.await('INSERT INTO pager_messages (id, message, user) VALUES (?, ?, ?)', {newID , currentMessage.text, otherCitizenID})
                    MySQL.insert.await('INSERT INTO pager_messages_users (user, message) VALUES (?, ?)', {currentCitizenID, newID})
                    currentMessage.isNew = nil
                    print(string.format("added #%s message from %s to %s", newID, otherCitizenID, currentCitizenID))
                end
            end
        end
	end
end

--------------------------------------------------------------------------
-- Callback to get pager data from server
--------------------------------------------------------------------------
lib.callback.register('96rp-pager:server:GetPagerData', function(source)
    -- wait until player is loaded
    while exports.qbx_core:GetPlayer(source) == nil do
        Wait(100)
    end

    -- wait until pagerd data is loaded
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    while pagersList[citizenid] == nil do
        Wait(100)
    end
    return pagersList[citizenid]
end)

--------------------------------------------------------------------------
-- Saves a new contact
--------------------------------------------------------------------------
RegisterNetEvent('96rp-pager:server:SaveContact', function(name, number)
    local src = source
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid
    local contacts = pagersList[citizenid].contacts
    local contactAlreadyExists = false

    -- check if contact already exists
    for i = 1, #contacts do
        local contact = contacts[i]
        if contact.number == number then
            contactAlreadyExists = true

            --if contacts has the same name, dont change entithing else change name
            if contact.name ~= name then
                contact.name = name
                contact.isUpdated = true
            end
            contact.removed = nil
        end
    end

    -- save contact if new
    if not contactAlreadyExists then
        table.insert(contacts, #contacts + 1, {
            name = name,
            number = number,
            isNew = true
        })
    end
end)

--------------------------------------------------------------------------
-- Removes given contact
--------------------------------------------------------------------------
RegisterNetEvent('96rp-pager:server:RemoveContact', function(number)
    local src = source
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid
    local contacts = pagersList[citizenid].contacts

    for id, contact in pairs(contacts) do

        if contact.number == number then

            -- if contact exists only localy
            if contact.id == nil then
                table.remove(contacts, id)

            -- if contact exists in db
            elseif contact.removed ~= true then
                contacts[id].removed = true
            end
        end
    end
end)

RegisterNetEvent('96rp-pager:server:PlayAnimation', function(animation)
    local src = source
    local playerPed = GetPlayerPed(src)
    if animation == 'getPagerOutOfPocket' then
        TaskPlayAnim(playerPed, Config.Animations.getPagerOutOfPocket.dict, Config.Animations.getPagerOutOfPocket.name, 8.0, 8.0, Config.Animations.getPagerOutOfPocket.time, Config.Animations.getPagerOutOfPocket.flag, 0.0, false, false, false)
    elseif animation == 'usePager' then
        TaskPlayAnim(playerPed, Config.Animations.usePager.dict, Config.Animations.usePager.name, 8.0, 8.0, Config.Animations.usePager.time, Config.Animations.usePager.flag, 0.0, false, false, false)
    else
        TaskPlayAnim(playerPed, Config.Animations.putPagerInPocket.dict, Config.Animations.putPagerInPocket.name, 8.0, 8.0, Config.Animations.putPagerInPocket.time, Config.Animations.putPagerInPocket.flag, 0.0, false, false, false)
    end
end)

--------------------------------------------------------------------------
-- Command for texting other players
--------------------------------------------------------------------------
RegisterCommand("pager", function(source, args, rawCommand)
    local citizenid = exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    local pagerUser = pagersList[citizenid]
    local contact = args[1]

    -- check if contact is a name or number
    if tonumber(contact) == nil then

        for _, contactData in pairs(pagerUser.contacts) do

            -- check if name actually exists in contacts (upper to prevent upper/lower errors)
            if string.upper(contactData.name) == string.upper(contact) then
                contact = contactData.number
            end
        end
    end

    -- merges all words after contact into one string
    local message = args[2]

    for i = 3, #args
    do
        message = message .. " " .. args[i]
    end

    if message ~= nil then

        local userFound = false

        for currentCitizenid, values in pairs(pagersList) do

            -- check if user exists (and is online too)
            if values.number == tonumber(contact) then
                local messages = pagersList[currentCitizenid].messages
                local chatType = 'Private message'

                table.insert(messages, #messages + 1, {
                    number = pagerUser.number,
                    chatType = chatType,
                    text = message,
                    isNew = true
                })
                
                TriggerClientEvent('96rp-pager:pager:received', values.serverid, pagerUser.number, chatType, message)
                userFound = true
            end
        end

        -- if user not found, check in config for dispatch services or groupchats
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
    end
end, false)

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